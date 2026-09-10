{
  inputs,
  self,
  ...
}:
let
  mkHome =
    {
      hostName,
      system,
      modules,

      # Defaults track unstable. Eta overrides all three so its standalone home
      # config is built from the same channel as the host it runs on.
      nixpkgs ? inputs.nixpkgs,
      homeManager ? inputs.home-manager,
      stylix ? inputs.stylix,
    }:
    homeManager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;

        config.allowUnfree = true;
        overlays = [
          self.overlays.additions
          self.overlays.modifications
          self.overlays.firefox-addons
        ];
      };

      extraSpecialArgs = { inherit inputs self hostName; };

      modules = [
        stylix.homeModules.stylix
        self.homeModules.persistence

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

      (
        { pkgs, ... }:
        {
          programs.tor-browser.forceLibcAllocator = true;

          home.packages = with pkgs; [
            airtame
            freecad-wayland
          ];
        }
      )
    ];

    eta = with self.homeModules; [
      git
      gpg
      fish
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
in
{
  flake = {
    homeModuleSets = bastianModules;
    homeConfigurations = {
      "bastian@epsilon" = mkHome {
        hostName = "epsilon";
        system = "x86_64-linux";
        modules = bastianModules.epsilon;
      };

      "bastian@delta" = mkHome {
        hostName = "delta";
        system = "x86_64-linux";
        modules = bastianModules.delta;
      };

      "bastian@eta" = mkHome {
        hostName = "eta";
        system = "aarch64-linux";
        modules = bastianModules.eta;

        nixpkgs = inputs.nixpkgs-stable;
        homeManager = inputs.home-manager-stable;
        stylix = inputs.stylix-stable;
      };
    };
  };
}
