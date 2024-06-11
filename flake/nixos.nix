{inputs, ...}: {
  flake.nixosConfigurations = let
    mkHost = hostname:
      inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs.inputs = inputs;
        modules = [
          # System configuration.
          ../nixos/${hostname}

          # Home Manager configuration.
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              users.bastian.imports = [../home/hosts/${hostname}];
              extraSpecialArgs.inputs = inputs;
            };
          }
        ];
      };
  in {
    limitless = mkHost "limitless";
  };
}
