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

  bastianModules = {
    epsilon = with self.homeModules; [
      bastian
      dconf
      desktop
      dotnet
      goxlr
      qemu
      rust
      sops
      ssh
      terminal
    ];

    delta = with self.homeModules; [
      bastian
      dconf
      desktop
      dotnet
      qemu
      rust
      sops
      ssh
      terminal

      ({pkgs, ...}: {
        home.packages = with pkgs; [
          airtame
          freecad-wayland
        ];
      })
    ];

    mu = with self.homeModules; [
      rust
      terminal
    ];

    eta = with self.homeModules; [
      git
      gpg
      zsh
      zoxide
      tmux
      ohMyPosh
      bat
      btop
      eza
      fastfetch
      fzf
      ripgrep
      sops
    ];
  };
in {
  flake = {
    homeModuleSets = bastianModules;
    homeConfigurations = {
      "bastian@epsilon" = mkHome {
        system = "x86_64-linux";
        modules = bastianModules.epsilon;
      };

      "bastian@delta" = mkHome {
        system = "x86_64-linux";
        modules = bastianModules.delta;
      };

      "bastian@mu" = mkHome {
        system = "aarch64-linux";
        modules = bastianModules.mu;
      };

      "bastian@eta" = mkHome {
        system = "aarch64-linux";
        modules = bastianModules.eta;
      };
    };
  };
}
