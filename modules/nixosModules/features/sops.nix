{inputs, ...}: {
  flake.nixosModules.sops = {pkgs, ...}: let
    secretsPath = toString inputs.secrets;
  in {
    imports = [inputs.sops-nix.nixosModules.sops];

    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFile = "${secretsPath}/secrets.yaml";

      age = {
        # Derive the age identity from the host's SSH ed25519 key.
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
