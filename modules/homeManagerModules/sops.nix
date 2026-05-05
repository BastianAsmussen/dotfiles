{inputs, ...}: {
  flake.homeModules.sops = {config, ...}: {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    sops = {
      defaultSopsFile = "${toString inputs.nix-secrets}/hosts/${config.networking.hostName}.yaml";

      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
  };
}
