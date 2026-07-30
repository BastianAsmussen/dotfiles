{ inputs, ... }:
{
  flake.nixosModules.sops =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      preferences.user = {
        name = lib.mkDefault inputs.nix-secrets.user.name;
        fullName = lib.mkDefault inputs.nix-secrets.user.full-name;
        email = lib.mkDefault inputs.nix-secrets.user.email;
      };

      environment.systemPackages = with pkgs; [
        sops
        age
      ];

      sops = {
        defaultSopsFile = "${toString inputs.nix-secrets}/hosts/${config.networking.hostName}.yaml";
        secrets."user/bastian/password-hash" = {
          sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
          neededForUsers = true;
        };

        age = {
          # Derive the age identity from the host's SSH ed25519 key.
          sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          keyFile = "/var/lib/sops-nix/key.txt";
          generateKey = true;
        };
      };

      users.users.${config.preferences.user.name}.hashedPasswordFile =
        config.sops.secrets."user/bastian/password-hash".path;
    };
}
