{
  inputs,
  self,
  ...
}: {
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

  flake.nixosModules.hostMu = {
    config,
    lib,
    ...
  }: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.language
      self.nixosModules.stylix

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Features
      self.nixosModules.homeManager
      self.nixosModules.topology

      # External modules
      inputs.nixos-avf.nixosModules.avf
      inputs.nix-index-database.nixosModules.nix-index
      inputs.stylix.nixosModules.stylix
    ];

    networking.hostName = "mu";
    topology.self = {
      hardware.info = "Android Phone";
      interfaces.wifi.physicalConnections = [
        (config.lib.topology.mkConnection "homeRouter" "wifi")
      ];
    };

    avf.defaultUser = config.preferences.user.name;
    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

    home-manager.userModules.bastian = self.homeModuleSets.mu;
  };
}
