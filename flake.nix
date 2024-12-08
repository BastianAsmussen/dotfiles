{
  description = "NixOS configuration flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";
    ags.url = "github:Aylur/ags/v1";
    matugen.url = "github:/InioX/Matugen";
    nixcord.url = "github:kaylorben/nixcord";
    docker-overlay.url = "github:BastianAsmussen/nixpkgs/docker-init";

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

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    self,
    ...
  } @ inputs: let
    inherit (builtins) attrNames readDir listToAttrs;
    inherit (self) outputs;

    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
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
    packages = forAllSystems ({pkgs}: import ./pkgs {inherit pkgs;});
    overlays = import ./overlays {inherit inputs;};
    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    nixosConfigurations = listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs userInfo lib;};
          modules = [
            ./hosts/${hostname}/configuration.nix
            ./modules/nixos

            {networking.hostName = hostname;}

            inputs.disko.nixosModules.disko
            inputs.stylix.nixosModules.stylix
          ];
        };
      })
      hosts);
  };
}
