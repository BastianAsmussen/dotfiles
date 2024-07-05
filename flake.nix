{
  description = "Top-level flake.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = pkgs.alejandra;

    nixosConfigurations.limitless = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/limitless/configuration.nix
        ./modules/nixos

        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
      ];
    };

    homeManagerModules.default = ./modules/home-manager;

    devShells.${system} = {
      python = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          python3
        ];
      };
    };
  };
}
