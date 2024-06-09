{
  description = "Top level NixOS Flake.";

  inputs = {
    # Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Unstable Packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko.
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager.
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, disko, home-manager, ... }@inputs: let
    inherit (self) outputs;

    systems = [
      "x86_64-linux"
    ];

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      
      config.allowUnfree = true;
    };

    forAllSystems = nixpkgs.lib.genAttrs systems;
  in  {
    overlays.unstable = final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = prev.config.allowUnfree;
      };
    };

    nixpkgs.overlays = [
      self.overlays.unstable
    ];

    nixosConfigurations.limitless = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs;

        meta = { hostname = "limitless"; };
      };
      system = "x86_64-linux";
      modules = [
        # Modules.
        disko.nixosModules.disko
      	
	# System Specific.
      	./machines/limitless/hardware-configuration.nix
        ./machines/limitless/disko-config.nix
        
	# General.
        ./configuration.nix

	# Home Manager.
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.bastian = import ./home/home.nix;
        }
      ];
    };

    homeConfigurations.bastian = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };

      modules = [
	./home.nix
      ];
    };
  };
}

