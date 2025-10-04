{
  inputs,
  pkgs,
  ...
}: let
  secretsPath = builtins.toString inputs.secrets;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  environment.systemPackages = [pkgs.sops];
  sops = {
    defaultSopsFile = "${secretsPath}/secrets.yaml";
    validateSopsFiles = false;

    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };
}
