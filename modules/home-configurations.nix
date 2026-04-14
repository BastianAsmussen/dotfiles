{
  inputs,
  self,
  ...
}: let
  mkHome = {
    system,
    modules,
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system;

        config.allowUnfree = true;
        overlays = [self.overlays.additions self.overlays.modifications];
      };

      extraSpecialArgs = {inherit inputs self;};

      modules =
        [
          inputs.stylix.homeModules.stylix

          # Baseline required by standalone home-manager.
          {
            home = {
              username = "bastian";
              homeDirectory = "/home/bastian";
              stateVersion = "26.05";
            };

            programs.home-manager.enable = true;
          }
        ]
        ++ modules;
    };
in {
  flake.homeConfigurations = {
    "bastian@lambda" = mkHome {
      system = "x86_64-linux";
      modules = with self.homeModules; [
        terminal
        desktop
        goxlr
        sops
        dconf
        dotnet
        rust
        qemu
        bastian
      ];
    };

    "bastian@delta" = mkHome {
      system = "x86_64-linux";
      modules = with self.homeModules; [
        terminal
        desktop
        sops
        ssh
        dconf
        dotnet
        rust
        qemu
        bastian

        ({pkgs, ...}: {
          home.packages = with pkgs; [
            airtame
            freecad-wayland
          ];
        })
      ];
    };

    "bastian@mu" = mkHome {
      system = "aarch64-linux";
      modules = with self.homeModules; [
        terminal
        rust
      ];
    };

    "bastian@eta" = mkHome {
      system = "aarch64-linux";
      modules = with self.homeModules; [
        git
        zsh
        zoxide
        tmux
        ohMyPosh
        bat
        btop
        direnv
        eza
        fastfetch
        fzf
        ripgrep
        sops
        qemu
      ];
    };
  };
}
