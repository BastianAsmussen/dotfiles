{
  description = "Top-level flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    old-monero.url = "github:nixos/nixpkgs/080a4a27f206d07724b88da096e27ef63401a504";

    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";
    ags.url = "github:Aylur/ags";
    matugen.url = "github:InioX/matugen";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord.url = "github:kaylorben/nixcord";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems
      (system: fn {pkgs = import nixpkgs {inherit system;};});
  in {
    packages = forAllSystems ({pkgs}: import ./pkgs nixpkgs.legacyPackages.${pkgs.system});
    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    nixosConfigurations = {
      limitless = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/limitless/configuration.nix
          ./modules/nixos

          inputs.disko.nixosModules.disko
          inputs.stylix.nixosModules.stylix
        ];
      };

      judgeman = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/judgeman/configuration.nix
          ./modules/nixos

          inputs.disko.nixosModules.disko
          inputs.stylix.nixosModules.stylix
        ];
      };
    };

    devShells = forAllSystems ({pkgs}: {
      rust = import ./shells/rust {inherit pkgs;};
    });
  };
}
