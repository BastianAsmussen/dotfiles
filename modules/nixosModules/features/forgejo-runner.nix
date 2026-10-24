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
      # Codeberg's published ED25519 host key (docs.codeberg.org/security/ssh-fingerprint,
      # SHA256:mIlxA9k46MmM6qdJOdMnAQpzGxF4WIVVL+fj+wZbw0g).
      codebergPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
      codebergHostKey = "codeberg.org ${codebergPublicKey}";
    in
    {
      # Trust Codeberg system-wide via /etc/ssh/ssh_known_hosts. CI jobs run on
      # the host executor and don't share the runner service's $HOME, so the
      # per-home known_hosts below isn't visible to them; the global file is the
      # only one their `git push` over SSH will consult without prompting.
      programs.ssh.knownHosts.codeberg = {
        hostNames = [ "codeberg.org" ];
        publicKey = codebergPublicKey;
      };

      sops.secrets = {
        "forgejo/runner-token" = { };
        "forgejo/deploy-key" = { };
      };

      # CI builds saturate every core and can be scheduled at any other time.
      # Stopping the runner lets an in-flight job finish; it just stops picking
      # up new ones.
      gamemode.pauseUnits = [ "forgejo-runner-${hostname}.service" ];

      # Disk-backed so the ISO job's workdir copy stays off the tmpfs root.
      persistence.directories = [ "/var/lib/private/forgejo-runner" ];

      services.forgejo-runner.instances.${hostname} = {
        enable = true;

        # The `:host` label is what makes the module put hostPackages on the
        # job PATH (host executor); jobs then run directly against this
        # machine's Nix daemon and store, so CI builds warm cache.asmussen.tech.
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
          server.connections.default = {
            url = "https://codeberg.org/";
            uuid = inputs.nix-secrets.hosts.${hostname}.forgejo-runner-uuid;
            labels = [ "nix:host" ];
          };
        };

        secrets.server.connections.default.token_url = config.sops.secrets."forgejo/runner-token".path;
      };

      systemd.services."forgejo-runner-${hostname}".serviceConfig = {
        ExecStartPre = [
          (pkgs.writeShellScript "forgejo-runner-${hostname}-pre" ''
            install -d -m 700 "$HOME/.ssh"
            install -m 600 "$CREDENTIALS_DIRECTORY/deploy-key" "$HOME/.ssh/id_ed25519"
            printf '%s\n' ${lib.escapeShellArg codebergHostKey} > "$HOME/.ssh/known_hosts"
          '')
        ];

        LoadCredential = [ "deploy-key:${config.sops.secrets."forgejo/deploy-key".path}" ];
      };
    };
}
