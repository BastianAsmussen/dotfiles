{ inputs, ... }:
{
  flake.nixosModules.forgejoRunner =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hostname = config.networking.hostName;
      # Codeberg host key (docs.codeberg.org/security/ssh-fingerprint).
      codebergPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
      codebergHostKey = "codeberg.org ${codebergPublicKey}";
    in
    {
      # Host jobs need global known_hosts; they do not share the runner's home.
      programs.ssh.knownHosts.codeberg = {
        hostNames = [ "codeberg.org" ];
        publicKey = codebergPublicKey;
      };

      sops.secrets = {
        "forgejo/runner-token" = { };
        "forgejo/deploy-key" = { };
      };

      # Stop scheduling CI jobs during games; in-flight jobs can finish.
      gamemode.pauseUnits = [ "gitea-runner-${hostname}.service" ];

      # Persist the DynamicUser state that holds the runner registration.
      persistence.directories = [ "/var/lib/private/gitea-runner" ];

      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.${hostname} = {
          enable = true;
          name = hostname;
          url = "https://codeberg.org";

          # Satisfy the module's token assertion while legacy registration is
          # disabled.
          token = "unused";

          # CI jobs use the host Nix store and warm cache.asmussen.tech.
          labels = [ "nix:host" ];
          hostPackages = with pkgs; [
            config.nix.package
            bash
            coreutils
            curl
            gawk
            git
            gnugrep
            gnused
            gnutar
            gzip
            jq
            nodejs
            openssh
          ];

          settings = {
            runner.labels = [ "nix:host" ];
            server.connections.codeberg = {
              url = "https://codeberg.org/";
              uuid = inputs.nix-secrets.hosts.${hostname}.forgejo-runner-uuid;
              token_url = "file:$CREDENTIALS_DIRECTORY/token.txt";
              labels = [ "nix:host" ];
            };
          };
        };
      };

      # Pass token_url through a systemd credential and replace deprecated
      # registration.
      systemd.services."gitea-runner-${hostname}".serviceConfig = {
        ExecStartPre = lib.mkForce [
          (pkgs.writeShellScript "forgejo-runner-${hostname}-pre" ''
            mkdir -p "$STATE_DIRECTORY/${hostname}"

            install -d -m 700 "$HOME/.ssh"
            install -m 600 "$CREDENTIALS_DIRECTORY/deploy-key" "$HOME/.ssh/id_ed25519"
            printf '%s\n' ${lib.escapeShellArg codebergHostKey} > "$HOME/.ssh/known_hosts"
          '')
        ];

        LoadCredential = [
          "token.txt:${config.sops.secrets."forgejo/runner-token".path}"
          "deploy-key:${config.sops.secrets."forgejo/deploy-key".path}"
        ];
      };
    };
}
