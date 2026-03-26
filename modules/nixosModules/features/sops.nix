{inputs, ...}: {
  flake.nixosModules.sops = {pkgs, ...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFile = "${toString inputs.nix-secrets}/secrets.yaml";

      age = {
        # Use the host's SSH host ed25519 key as the age identity. sops-nix
        # will derive the age key from it at activation time, so no separate
        # key file is needed on disk.
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
