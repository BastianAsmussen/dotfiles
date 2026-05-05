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
        # Derive the age identity from the host's SSH ed25519 key.
        sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };
}
