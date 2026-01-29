{
  description = "NixOS configuration flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-fork.url = "github:BastianAsmussen/nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    home-manager.url = "github:nix-community/home-manager";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    ags.url = "github:Aylur/ags/v1";
    stylix.url = "github:danth/stylix";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    schizofox.url = "github:schizofox/schizofox";
    nixcord.url = "github:kaylorben/nixcord";
    glove80-zmk = {
      url = "github:moergo-sc/zmk";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    self,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (builtins) attrNames readDir listToAttrs;

    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
    ];

    hosts = attrNames (readDir ./hosts);
    forAllSystems = fn:
      nixpkgs.lib.genAttrs systems
      (system:
        fn {
          pkgs = import nixpkgs {inherit system;};
        });

    lib = nixpkgs.lib.extend (final: _prev: {
      custom = import ./lib final;
    });

    userInfo = {
      username = "bastian";
      email = "bastian@asmussen.tech";
      fullName = "Bastian Asmussen";
      icon = ./assets/icons/bastian.png;
    };
  in {
    apps = forAllSystems ({pkgs}: import ./apps {inherit inputs pkgs lib;});
    checks = forAllSystems ({pkgs}: {
      library = pkgs.callPackage ./tests {inherit pkgs lib;};
    });

    devShells = forAllSystems ({pkgs}: {
      default = import ./shell.nix {inherit pkgs;};
    });

    formatter = forAllSystems ({pkgs}: pkgs.alejandra);
    overlays = import ./overlays {inherit inputs lib;};
    packages = forAllSystems ({pkgs}: import ./pkgs {inherit pkgs;});
    templates = import ./templates;

    nixosConfigurations = listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs userInfo lib self;};
          modules = [
            ./hosts/${hostname}/configuration.nix
            ./modules/nixos

            {networking.hostName = hostname;}

            inputs.disko.nixosModules.disko
            inputs.stylix.nixosModules.stylix
            inputs.nix-index-database.nixosModules.nix-index
          ];
        };
      })
      hosts);
  };
}
