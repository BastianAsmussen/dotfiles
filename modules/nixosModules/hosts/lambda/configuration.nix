{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.lambda = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostLambda
    ];
  };

  flake.nixosModules.hostLambda = {pkgs, ...}: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.bootloader
      self.nixosModules.language
      self.nixosModules.misc
      self.nixosModules.stylix

      # Desktop
      self.nixosModules.greeter
      self.nixosModules.hyprland
      self.nixosModules.pipewire

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Security
      self.nixosModules.gpg
      self.nixosModules.security
      self.nixosModules.ssh
      self.nixosModules.tailscale
      self.nixosModules.yubiKey

      # Features
      self.nixosModules.bluetooth
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.homeManager
      self.nixosModules.monero
      self.nixosModules.networkManager
      self.nixosModules.nvidia
      self.nixosModules.gaming
      self.nixosModules.goxlr
      self.nixosModules.virtualisation

      # Host-specific hardware
      self.diskoConfigurations.hostLambda

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index

      # Hardware-specific
      inputs.nixos-hardware.nixosModules.common-cpu-amd
    ];

    networking.hostName = "lambda";
    desktop = {
      environment.hyprland.monitors = [
        "DP-1, 1920x1080@240, 1920x0, 1, vrr, 2"
        "HDMI-A-1, 1920x1080@60, 0x0, 1"
      ];

      greeter.gdm.enable = true;
    };

    monero.mining = {
      enable = false;
      pool = "pool.hashvault.pro:80";
      wallet = "8AzWTLBtPhkBqAU1m9TQW42LTtPwoKb4s4Sgo4uYY6TY1pNrrKYj2vFgGW9D5sBqi8VStmgViAZC82GfVcsqqLq77uJtWE7";
      maxUsagePercentage = 25;
    };

    bootloader.isMultiboot = true;

    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
      };

      open-webui.enable = true;
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
      goxlr

      # Other
      dconf
      dotnet
      rust
      qemu

      # Shared user profile
      bastian

      # Host-specific overrides
      {
        wayland.windowManager.hyprland.settings.input.accel_profile = "flat";
      }
    ];
  };
}
