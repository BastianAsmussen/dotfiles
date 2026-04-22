{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.epsilon = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostEpsilon
    ];
  };

  flake.nixosModules.hostEpsilon = {config, ...}: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.grub
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
      self.nixosModules.wireguard
      self.nixosModules.luksFido2
      self.nixosModules.yubiKey

      # Features
      self.nixosModules.japanese
      self.nixosModules.bluetooth
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.gaming
      self.nixosModules.goxlr
      self.nixosModules.homeManager
      self.nixosModules.jellyfin
      self.nixosModules.qbittorrent
      self.nixosModules.primaryBusy
      self.nixosModules.monero
      self.nixosModules.networkManager
      self.nixosModules.nginx
      self.nixosModules.nix-serve
      self.nixosModules.nvidia
      self.nixosModules.topology
      self.nixosModules.virtualisation
      self.nixosModules.website

      # Host-specific hardware
      self.diskoConfigurations.hostEpsilon

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index

      # Hardware-specific
      inputs.nixos-hardware.nixosModules.common-cpu-amd
    ];

    networking.hostName = "epsilon";
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

        wg0.physicalConnections = [
          (mkConnection "eta" "wg0")
        ];
      };
    };

    sops.secrets."wireguard/psk-eta-epsilon" = {};

    wireguard = {
      enable = true;
      ips = ["10.10.0.2/24"];
      peers = [
        {
          publicKey = inputs.nix-secrets.hosts.eta.wg-public-key;
          allowedIPs = ["10.10.0.1/32"];
          endpoint = "${inputs.nix-secrets.hosts.eta.ipv4_address}:51820";
          persistentKeepalive = 25;
          presharedKeyFile = config.sops.secrets."wireguard/psk-eta-epsilon".path;
        }
      ];
    };

    nix-serve-extras.bindAddress = "10.10.0.2";

    nginx = {
      acme.sharedHost = "asmussen.tech";

      redirects = let
        dkRedirect = domain: {
          inherit domain;

          enable = true;
          target = "https://asmussen.tech";
          ssl = {
            dnsProvider = "cloudflare";
            environmentFile = config.sops.templates."cloudflare-acme-env".path;
          };
        };
      in {
        dotfiles-dk = dkRedirect "dotfiles.dk";
        fansly-dk = dkRedirect "fansly.dk";
        tech-college-dk = dkRedirect "tech-college.dk";
        harvard-dk = dkRedirect "harvard.dk";
      };

      reverseProxies.jellyfin = {
        enable = true;
        domain = "jellyfin.asmussen.tech";
        location = "/";
        upstream = "http://localhost:8096";
        ssl = {
          dnsProvider = "cloudflare";
          environmentFile = config.sops.templates."cloudflare-acme-env".path;
        };
      };
    };

    security.acme.certs."asmussen.tech" = {
      extraDomainNames = ["*.asmussen.tech"];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-acme-env".path;

      inherit (config.services.nginx) group;
    };

    services = {
      nginx.virtualHosts = {
        "www.asmussen.tech" = {
          useACMEHost = "asmussen.tech";
          forceSSL = true;
          locations."/".return = "301 https://asmussen.tech$request_uri";
        };

        # Redirect legacy path to subdomain for existing bookmarks.
        "asmussen.tech".locations."/jellyfin".return = "301 https://jellyfin.asmussen.tech/";

        # qBittorrent WebUI proxied over TLS, bound to WG interface only.
        "qbittorrent.asmussen.tech" = {
          listen = [
            {
              addr = "10.10.0.2";
              port = 443;
              ssl = true;
            }
          ];

          onlySSL = true;
          useACMEHost = "asmussen.tech";
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString config.services.qbittorrent.webuiPort}";
            proxyWebsockets = true;
          };
        };
      };

      openssh.openFirewall = false;
    };

    # Resolve qbittorrent via WG IP locally so public DNS (*.asmussen.tech -> eta) is bypassed.
    networking = {
      hosts."10.10.0.2" = ["qbittorrent.asmussen.tech"];

      # Allow eta (mirror) and local SSH to reach proxied services over WireGuard.
      firewall.interfaces.wg0.allowedTCPPorts =
        config.services.openssh.ports
        ++ [
          config.services.nix-serve.port
          config.services.website.port
          8096 # Jellyfin
        ];
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

    primaryBusy.enable = true;
    btrfs.scrub.fileSystems = ["/" "/srv/media"];

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
      ssh
    ];
  };
}
