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
      self.nixosModules.btrfs
      self.nixosModules.ccache
      self.nixosModules.homeManager
      self.nixosModules.remoteBuilder
      self.nixosModules.kanata
      self.nixosModules.networkManager
      self.nixosModules.topology
      self.nixosModules.virtualisation
      self.nixosModules.wireguard
      self.nixosModules.mtls

      # Host-specific hardware
      self.diskoConfigurations.hostDelta

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
      inputs.nix-index-database.nixosModules.nix-index
    ];

    networking = {
      hostName = "delta";

      # Resolve qbittorrent to localhost; local nginx handles mTLS upstream.
      hosts."127.0.0.1" = ["qbittorrent.asmussen.tech"];
    };

    mtls.client = {
      enable = true;
      caCertPath = ../../../../keys/mtls-ca.crt;
      domains = ["qbittorrent.asmussen.tech"];
    };

    # Local reverse proxy: terminates TLS for the browser, presents ephemeral
    # mTLS client cert to epsilon upstream. Loopback only.
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."qbittorrent.asmussen.tech" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 443;
            ssl = true;
          }
          {
            addr = "127.0.0.1";
            port = 80;
          }
          {
            addr = "[::1]";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::1]";
            port = 80;
          }
        ];
        forceSSL = true;
        sslCertificate = "/run/mtls/local-qbittorrent.asmussen.tech.crt";
        sslCertificateKey = "/run/mtls/local-qbittorrent.asmussen.tech.key";

        locations."/" = {
          proxyPass = "https://10.10.0.1";
          proxyWebsockets = true;
          extraConfig = ''
            # Present ephemeral mTLS client cert to epsilon through eta's SNI proxy.
            proxy_ssl_certificate     /run/mtls/client.crt;
            proxy_ssl_certificate_key /run/mtls/client.key;
            proxy_ssl_server_name on;
            proxy_ssl_name qbittorrent.asmussen.tech;
            proxy_set_header Host qbittorrent.asmussen.tech;
          '';
        };
      };
    };

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

    sops.secrets."wireguard/psk-eta-delta" = {};

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

    home-manager.userModules.bastian = self.homeModuleSets.delta;
  };
}
