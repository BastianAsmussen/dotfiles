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

  flake.nixosModules.hostDelta = {config, ...}: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.language
      self.nixosModules.misc
      self.nixosModules.grub
      self.nixosModules.stylix

      # Desktop
      self.nixosModules.greeter
      self.nixosModules.niri
      self.nixosModules.pipewire

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Security
      self.nixosModules.security
      self.nixosModules.sops
      self.nixosModules.gpg
      self.nixosModules.yubiKey

      # Features
      self.nixosModules.japanese
      self.nixosModules.bluetooth
      self.nixosModules.btop
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.homeManager
      self.nixosModules.remoteBuilder
      self.nixosModules.kanata
      self.nixosModules.networkManager
      self.nixosModules.nginx
      self.nixosModules.topology
      self.nixosModules.virtualisation
      self.nixosModules.wireguard

      # Host-specific hardware
      self.diskoConfigurations.hostDelta

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index
    ];

    networking.hostName = "delta";

    remoteBuilder.jumpHost = "10.10.0.1";

    topology.self = let
      inherit (config.lib.topology) mkConnection;
    in {
      hardware.info = "Intel Laptop";
      interfaces = {
        wifi.physicalConnections = [
          (mkConnection "homeRouter" "wifi")
        ];

        wg0.physicalConnections = [
          (mkConnection "eta" "wg0")
        ];
      };
    };

    wireguard = {
      enable = true;
      ips = ["10.10.0.3/24" "fd00:10:10::3/64"];
      peers = [
        {
          publicKey = inputs.nix-secrets.hosts.eta.wg-public-key;
          peerIps = self.nixosConfigurations.eta.config.wireguard.ips;
          endpoint = "${inputs.nix-secrets.hosts.eta.ipv4_address}:51820";
          persistentKeepalive = 25;
          presharedKeyFile = config.sops.secrets."wireguard/psk-eta-delta".path;
        }
      ];
    };

    desktop.greeter.gdm.enable = true;

    nginx = {
      openFirewall = false;
      acme.sharedHost = "asmussen.tech";

      reverseProxies.qbittorrent = {
        enable = true;
        domain = "qbittorrent.asmussen.tech";
        location = "/";
        upstream = "https://10.10.0.1";
        proxySSL = {
          clientCertificate = config.sops.secrets."mtls/delta-client-cert".path;
          clientCertificateKey = config.sops.secrets."mtls/delta-client-key".path;
          serverName = "qbittorrent.asmussen.tech";
          verify = false;
        };
      };
    };

    security.acme.certs."asmussen.tech" = {
      extraDomainNames = ["*.asmussen.tech"];
      dnsProvider = "cloudflare";
      environmentFile = config.sops.templates."cloudflare-acme-env".path;

      inherit (config.services.nginx) group;
    };

    users.users.acme.extraGroups = ["keys"];

    sops = {
      secrets = {
        "wireguard/psk-eta-delta" = {};
        "cloudflare-api-token" = {};
        "mtls/delta-client-cert".owner = "nginx";
        "mtls/delta-client-key".owner = "nginx";
      };

      templates."cloudflare-acme-env" = {
        owner = "acme";
        content = "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
      };
    };

    # Resolve qbittorrent to loopback so the browser hits the local mTLS proxy
    # instead of going out through eta.
    networking.hosts = {
      "127.0.0.1" = ["qbittorrent.asmussen.tech"];
      "::1" = ["qbittorrent.asmussen.tech"];
    };

    home-manager.userModules.bastian = self.homeModuleSets.delta;
  };
}
