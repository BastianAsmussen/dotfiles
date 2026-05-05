{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.HOSTNAME = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostHOSTNAME
    ];
  };

  flake.nixosModules.hostHOSTNAME = {lib, ...}: {
    imports = [
      # External modules.
      inputs.nix-index-database.nixosModules.nix-index
      inputs.stylix.nixosModules.stylix

      # Base modules.
      self.nixosModules.base
      self.nixosModules.language
      self.nixosModules.stylix

      # Nix.
      self.nixosModules.nh
      self.nixosModules.nix

      # Features.
      self.nixosModules.homeManager
      self.nixosModules.topology
    ];

    networking.hostName = "HOSTNAME";

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
