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

  flake.nixosModules.hostLambda = {config, ...}: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.bootloader
      self.nixosModules.language
      self.nixosModules.misc
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
      self.nixosModules.gpg
      self.nixosModules.security
      self.nixosModules.sops
      self.nixosModules.ssh
      self.nixosModules.tailscale
      self.nixosModules.luksFido2
      self.nixosModules.yubiKey

      # Features
      self.nixosModules.bluetooth
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.gaming
      self.nixosModules.goxlr
      self.nixosModules.homeManager
      self.nixosModules.ipfs
      self.nixosModules.jellyfin
      self.nixosModules.lambdaBusy
      self.nixosModules.monero
      self.nixosModules.networkManager
      self.nixosModules.nginx
      self.nixosModules.nix-serve
      self.nixosModules.nvidia
      self.nixosModules.topology
      self.nixosModules.virtualisation
      self.nixosModules.website

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
    topology.self = let
      inherit (config.lib.topology) mkConnection;
    in {
      hardware.info = "AMD Ryzen Desktop, NVIDIA GPU";
      interfaces = {
        lan = {
          network = "home";
          type = "ethernet";
          addresses = ["192.168.1.64"];
          physicalConnections = [
            (mkConnection "homeRouter" "eth1")
          ];
        };

        tailscale0.physicalConnections = [
          (mkConnection "delta" "tailscale0")
        ];
      };
    };

    desktop.greeter.gdm.enable = true;
    preferences.monitors = {
      "DP-1" = {
        width = 1920;
        height = 1080;
        refreshRate = 239.76;
        x = 1920;
        y = 0;
        scale = 1.0;
        vrr = "on-demand";
      };

      "HDMI-A-1" = {
        width = 1920;
        height = 1080;
        refreshRate = 60.0;
        x = 0;
        y = 0;
        scale = 1.0;
      };
    };

    monero.mining = {
      enable = false;
      pool = "pool.hashvault.pro:80";
      wallet = self.preferences.monero-wallet;
      maxUsagePercentage = 25;
    };

    bootloader.isMultiboot = true;
    lambdaBusy.enable = true;
    btrfs.scrub.fileSystems = ["/" "/run/media/bastian/Extra"];

    home-manager.userModules.bastian = with self.homeModules; [
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
}
