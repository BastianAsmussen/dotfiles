{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.mu = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostMu
    ];
  };

  flake.nixosModules.hostMu =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        # External modules.
        inputs.nixos-avf.nixosModules.avf
        inputs.nix-index-database.nixosModules.nix-index
        inputs.stylix.nixosModules.stylix

        # Base modules.
        self.nixosModules.base
        self.nixosModules.language
        self.nixosModules.stylix

        # Nix.
        self.nixosModules.nix
        self.nixosModules.nh

        # Features.
        self.nixosModules.homeManager
        self.nixosModules.topology
      ];

      networking.hostName = "mu";
      topology.self = {
        hardware.info = "NixOS via AVF";
        guestType = "avf";
        parent = "muPhone";
      };

      avf.defaultUser = config.preferences.user.name;
      preferences.user.uid = 1001;

      nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

      home-manager.userModules.bastian = self.homeModuleSets.mu;
    };
}
