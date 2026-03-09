{
  inputs,
  self,
  config,
  ...
}: {
  flake.nixosConfigurations.delta = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;

      inherit (config.flake) lib;
      inherit (config.flake.meta) userInfo;

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
      self.nixosModules.user
      self.nixosModules.language
      self.nixosModules.misc
      self.nixosModules.bootloader
      self.nixosModules.stylix

      # Desktop
      self.nixosModules.greeter
      self.nixosModules.hyprland
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
      self.nixosModules.networkManager
      self.nixosModules.homeManager
      self.nixosModules.virtualisation

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index

      # Host-specific hardware
      ./_hardware-configuration.nix
      ./_disko-config.nix

      # Hardware-specific
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-gpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-laptop
    ];

    networking.hostName = "delta";

    desktop = {
      environment.hyprland.monitors = ["eDP-1, 1920x1080@60, 0x0, 1"];
      greeter.gdm.enable = true;
    };

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
      hyprland
      hyprlock
      ags
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
