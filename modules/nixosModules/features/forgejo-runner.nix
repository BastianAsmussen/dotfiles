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
      programs.ssh.knownHosts.codeberg = {
        hostNames = [ "codeberg.org" ];
        publicKey = codebergPublicKey;
      };

      sops.secrets = {
        "forgejo/runner-token" = { };
        "forgejo/deploy-key" = { };
      };

      gamemode.pauseUnits = [ "forgejo-runner-${hostname}.service" ];
      persistence.directories = [
        "/var/lib/private/gitea-runner"
        "/var/lib/private/forgejo-runner"
      ];

      services.forgejo-runner = {
        instances.${hostname} = {
          enable = true;
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
            # CI jobs use the host Nix store.
            runner.labels = [ "nix:host" ];
            server.connections.default = {
              url = "https://codeberg.org/";
              labels = [ "nix:host" ];
              uuid = inputs.nix-secrets.hosts.${hostname}.forgejo-runner-uuid;
              token_url = "file:$CREDENTIALS_DIRECTORY/token.txt";
            };
          };
        };
      };

      # Hand secret token to `token_url` through a systemd credential.
      systemd.services."forgejo-runner-${hostname}".serviceConfig = {
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
