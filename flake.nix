{
  description = "NixOS configuration flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-fork.url = "github:BastianAsmussen/nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    hyprland.url = "github:hyprwm/Hyprland";
    ags.url = "github:Aylur/ags/v1";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    schizofox.url = "github:schizofox/schizofox";
    nixcord.url = "github:FlameFlag/nixcord";

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks.flakeModule
      ];

      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
      ];

      flake = {
        lib = nixpkgs.lib.extend (final: _prev: {
          custom = import ./lib final;
        });

        overlays = import ./overlays {
          inherit inputs;
          inherit (self) lib;
        };

        templates = import ./templates;
        nixosConfigurations = let
          inherit (builtins) attrNames readDir listToAttrs;

          hosts = attrNames (readDir ./hosts);
          userInfo = {
            username = "bastian";
            email = "bastian@asmussen.tech";
            fullName = "Bastian Asmussen";
            icon = ./assets/icons/bastian.png;
          };
        in
          listToAttrs (map (hostname: {
              name = hostname;
              value = nixpkgs.lib.nixosSystem {
                specialArgs = {
                  inherit inputs userInfo self;
                  inherit (self) lib;

                  outputs = self;
                };

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

      perSystem = {
        pkgs,
        config,
        ...
      }: {
        formatter = pkgs.alejandra;
        packages = import ./pkgs {inherit pkgs;};
        pre-commit.settings.hooks = {
          deadnix = {
            enable = true;
            settings.edit = true;
          };

          statix.enable = true;
          alejandra.enable = true;
          flake-checker = {
            enable = true;
            args = ["--no-telemetry"];
          };
        };

        checks = {
          library = pkgs.callPackage ./tests {
            inherit pkgs;
            inherit (self) lib;
          };

          # Check for dead Nix code.
          deadnix =
            pkgs.runCommandLocal "deadnix" {
              buildInputs = [pkgs.deadnix];
              src = ./.;
            } ''
              deadnix --fail "$src"
              touch $out
            '';

          # Lint Nix files.
          statix =
            pkgs.runCommandLocal "statix" {
              buildInputs = [pkgs.statix];
              src = ./.;
            } ''
              statix check "$src"
              touch $out
            '';

          # Check flake inputs.
          flake-checker =
            pkgs.runCommandLocal "flake-checker" {
              buildInputs = [pkgs.flake-checker];
              src = ./.;
            } ''
              flake-checker --fail-mode --no-telemetry "$src/flake.lock"
              touch $out
            '';
        };

        devShells.default = pkgs.mkShell {
          inherit (config.pre-commit) shellHook;

          inputsFrom = [(import ./shell.nix {inherit pkgs;})];
        };
      };
    };
}
