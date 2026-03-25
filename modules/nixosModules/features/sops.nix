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

    # Inject the city after noctalia-shell's IPC socket is ready.
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

      # Derive the age identity from the host's SSH ed25519 key.
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      secrets."user/city".owner = config.preferences.user.name;
    };

    preferences.autostart = [setLocationScript];
  };
}
