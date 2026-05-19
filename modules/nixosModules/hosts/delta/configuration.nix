{
  inputs,
  self,
  ...
}:
{
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

  flake.nixosModules.hostDelta =
    { config, ... }:
    {
      imports = [
        # External modules.
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        inputs.nix-index-database.nixosModules.nix-index

        # Host-specific hardware.
        self.diskoConfigurations.hostDelta

        # Base modules.
        self.nixosModules.base
        self.nixosModules.grub
        self.nixosModules.language
        self.nixosModules.misc
        self.nixosModules.stylix

        # Desktop.
        self.nixosModules.greeter
        self.nixosModules.niri
        self.nixosModules.pipewire

        # Nix.
        self.nixosModules.nh
        self.nixosModules.nix

        # Security.
        self.nixosModules.acmeShared
        self.nixosModules.gpg
        self.nixosModules.security
        self.nixosModules.sops
        self.nixosModules.yubiKey
        self.nixosModules.wireguard

        # Features.
        self.nixosModules.bluetooth
        self.nixosModules.btop
        self.nixosModules.btrfs
        self.nixosModules.ccache
        self.nixosModules.homeManager
        self.nixosModules.japanese
        self.nixosModules.kanata
        self.nixosModules.networkManager
        self.nixosModules.nginx
        self.nixosModules.remoteBuilder
        self.nixosModules.syncthing
        self.nixosModules.topology
        self.nixosModules.virtualisation
        self.nixosModules.winapps
      ];

      winapps.enable = true;

      japanese.enable = true;
      networking.hostName = "delta";
      remoteBuilder.jumpHost = "10.10.0.1";
      acmeShared.enable = true;

      environment.memoryAllocator.provider = "graphene-hardened";
      topology.self =
        let
          inherit (config.lib.topology) mkConnection;
        in
        {
          hardware.info = "Intel Laptop";
          interfaces = {
            wifi.physicalConnections = [
              (mkConnection "homeRouter" "wifi")
            ];

            wg0.physicalConnections = [
              (mkConnection "eta" "wg0")
            ];
          };

          services.syncthing = {
            name = "Syncthing";
            icon = "services.syncthing";
          };
        };

      wireguard = {
        enable = true;
        ips = [
          "10.10.0.3/24"
          "fd00:10:10::3/64"
        ];

        peers = [
          {
            publicKey = inputs.nix-secrets.hosts.eta.wg-public-key;
            allowedIPs = [
              "10.10.0.0/24"
              "fd00:10:10::/64"
            ];

            endpoint = "${inputs.nix-secrets.hosts.eta.ipv4_address}:51820";
            persistentKeepalive = 25;
            presharedKeyFile = config.sops.secrets."wireguard/psk-eta-delta".path;
          }
        ];
      };

      nginx = {
        openFirewall = false;
        acme.sharedHost = "asmussen.tech";
        reverseProxies = {
          qbittorrent = {
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

          shoko = {
            enable = true;
            domain = "shoko.asmussen.tech";
            location = "/";
            upstream = "https://10.10.0.1";
            proxySSL = {
              clientCertificate = config.sops.secrets."mtls/delta-client-cert".path;
              clientCertificateKey = config.sops.secrets."mtls/delta-client-key".path;
              serverName = "shoko.asmussen.tech";
              verify = false;
            };
          };
        };
      };

      sops.secrets = {
        "wireguard/psk-eta-delta" = { };
        "mtls/delta-client-cert".owner = "nginx";
        "mtls/delta-client-key".owner = "nginx";
      };

      # Resolve mTLS-protected services to loopback so the browser hits the local
      # mTLS proxy instead of going out through eta.
      networking.hosts = {
        "127.0.0.1" = [
          "qbittorrent.asmussen.tech"
          "shoko.asmussen.tech"
        ];

        "::1" = [
          "qbittorrent.asmussen.tech"
          "shoko.asmussen.tech"
        ];
      };

      home-manager.userModules.bastian = self.homeModuleSets.delta;
    };
}
