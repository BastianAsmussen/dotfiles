{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.delta = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostDelta
    ];
  };

  flake.nixosModules.hostDelta = {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.language
      self.nixosModules.misc
      self.nixosModules.bootloader
      self.nixosModules.stylix

      # Desktop
      self.nixosModules.greeter
      self.nixosModules.niri
      self.nixosModules.wallpaper
      self.nixosModules.pipewire

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Security
      self.nixosModules.security
      self.nixosModules.gpg
      self.nixosModules.yubiKey
      self.nixosModules.tailscale

      # Features
      self.nixosModules.bluetooth
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.networkManager
      self.nixosModules.homeManager
      self.nixosModules.virtualisation

      # Host-specific hardware
      self.diskoConfigurations.hostDelta

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index
    ];

    networking.hostName = "delta";

    desktop.greeter.gdm.enable = true;

    home-manager.userModules.bastian = with self.homeModules; [
      # Terminal
      nixvim
      git
      zsh
      zoxide
      nixIndex
      tmux
      tmuxSessionizer
      gpg
      ohMyPosh
      bat
      btop
      direnv
      distrobox
      eza
      fastfetch
      fzf
      ripgrep
      passwordStore

      # Desktop
      alacritty
      firefox
      spicetify
      nixcord

      # Other
      dconf
      dotnet
      rust
      qemu

      # Shared user profile
      bastian

      # Host-specific user packages
      ({pkgs, ...}: {
        home.packages = with pkgs; [
          airtame
          freecad-wayland
        ];
      })
    ];
  };
}
