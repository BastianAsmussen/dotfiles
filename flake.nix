{
  description = "Top level NixOS Flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Unstable Packages
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, home-manager, nixpkgs-unstable, ... }@inputs: let
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

    overlays.additions = final: _prev: import ./pkgs final.pkgs;

    overlays.unstable = final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = prev.config.allowUnfree;
      };
    };

    nixpkgs.overlays = [
      self.overlays.unstable
      alacritty-theme.overlays.default
      templ.overlays.default
    ];

    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    nixosConfigurations.overlord = nixpkgs.lib.nixosSystem {
      specialArgs = {
        meta = { hostname = "overlord"; };
      };
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko

        ./machines/overlord/hardware-configuration.nix
        ./machines/overlord/disko-config.nix
        ./configuration.nix

        ({ config, pkgs, ...}: {
          nixpkgs.overlays = [
            self.overlays.unstable
          ];
        })
        home-manager.nixosModules.home-manager
        {
          # home-manager.useGlobalPkgs = true;
          # home-manager.useUserPackages = true;
          home-manager.users.bastian = import ./home/home.nix;
        }
      ];
    };
    nixosConfigurations.work = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs;
        meta = { hostname = "work"; };
      };
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko

        ./machines/work/hardware-configuration.nix
        ./machines/work/disko-config.nix
        ./configuration.nix

        ({ config, pkgs, ...}: {
          nixpkgs.overlays = [
            self.overlays.unstable
            self.overlays.additions
          ];
        })
        home-manager.nixosModules.home-manager
        {
          # home-manager.useGlobalPkgs = true;
          # home-manager.useUserPackages = true;
          home-manager.users.bastian = import ./home/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
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
