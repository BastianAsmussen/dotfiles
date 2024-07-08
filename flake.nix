{
  description = "Top-level flake.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    nixosConfigurations.limitless = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/limitless/configuration.nix
        ./modules/nixos

        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
      ];
    };

    devShells = forAllSystems ({pkgs}: {
      rust = import ./shells/rust;
    });
  };
}
