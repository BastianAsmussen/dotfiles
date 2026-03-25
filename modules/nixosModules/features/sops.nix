{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sops = {
    pkgs,
    lib,
    config,
    ...
  }: let
    noctaliaExe = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell;

    # After noctalia-shell has started and its IPC socket is ready, inject the
    # city name from the sops secret.
    setLocationScript =
      # bash
      ''
        retries=0
        while ! ${noctaliaExe} ipc call state all > /dev/null 2>&1; do
          if [ "$retries" -ge 30 ]; then
            echo "noctalia-shell did not become ready in time; skipping location set..." >&2
            exit 1
          fi

          retries=$((retries + 1))
          sleep 1
        done

        ${noctaliaExe} ipc call location set "$(cat ${config.sops.secrets."user/city".path})" \
          || echo "Failed to set noctalia-shell location via IPC!" >&2
      '';
  in {
    imports = [inputs.sops-nix.nixosModules.sops];

    environment.systemPackages = [pkgs.sops];

    sops = {
      defaultSopsFile = ../../../secrets.yaml;

      # Use the host's SSH host ed25519 key as the age identity. sops-nix will
      # derive the age key from it at activation time, so no separate key file
      # is needed on disk.
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      secrets."user/city".owner = config.preferences.user.name;
    };

    preferences.autostart = [setLocationScript];
  };
}
