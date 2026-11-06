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
    {
      config,
      lib,
      ...
    }:
    {
      imports = [
        # External modules.
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        inputs.nix-index-database.nixosModules.nix-index
        inputs.home-manager.nixosModules.home-manager

        # Host-specific hardware.
        self.diskoConfigurations.hostDelta

        # Base modules.
        self.nixosModules.base
        self.nixosModules.language
        self.nixosModules.limine
        self.nixosModules.misc
        self.nixosModules.time
        self.nixosModules.stylix

        # Desktop.
        self.nixosModules.greeter
        self.nixosModules.niri
        self.nixosModules.pipewire

        # Nix.
        self.nixosModules.nix
        self.nixosModules.nh
        self.nixosModules.eh

        # Security.
        self.nixosModules.acmeShared
        self.nixosModules.gpg
        self.nixosModules.security
        self.nixosModules.sops
        self.nixosModules.tor
        self.nixosModules.yubiKey
        self.nixosModules.wireguard

        # Features.
        self.nixosModules.bluetooth
        self.nixosModules.monero
        self.nixosModules.btop
        self.nixosModules.btrfs
        self.nixosModules.ccache
        self.nixosModules.homeManager
        self.nixosModules.kanata
        self.nixosModules.dns
        self.nixosModules.networkManager
        self.nixosModules.caddy
        self.nixosModules.remoteBuilder
        self.nixosModules.syncthing
        self.nixosModules.topology
        self.nixosModules.virtualisation
        self.nixosModules.winapps
      ];

      winapps.enable = true;

      monero = {
        node.enable = false;
        mining.enable = false;
      };

      networking.hostName = "delta";
      preferences.noctalia.useIpLocation = true;
      acmeShared.enable = true;

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

      # Serve browsers on loopback; upstream TLS uses the system trust store.
      caddy.listenAddresses = [
        "127.0.0.1"
        "::1"
      ];

      services.caddy.virtualHosts =
        let
          mtlsNames = [
            "qbittorrent"
            "shoko"
            "sonarr"
            "radarr"
            "prowlarr"
          ];

          clientCert = config.sops.secrets."mtls/delta-client-cert".path;
          clientKey = config.sops.secrets."mtls/delta-client-key".path;
        in
        lib.genAttrs (map (name: "${name}.asmussen.tech") mtlsNames) (name: {
          extraConfig = ''
            reverse_proxy https://10.10.0.2:8443 {
              transport http {
                tls_client_auth ${clientCert} ${clientKey}
                tls_server_name ${name}
              }
            }
          '';
        });

      sops.secrets = {
        "wireguard/psk-eta-delta" = { };
        "mtls/delta-client-cert".owner = config.services.caddy.user;
        "mtls/delta-client-key".owner = config.services.caddy.user;
      };

      # Route mTLS services through the local proxy instead of eta.
      networking.hosts = {
        "127.0.0.1" = [
          "qbittorrent.asmussen.tech"
          "shoko.asmussen.tech"
          "sonarr.asmussen.tech"
          "radarr.asmussen.tech"
          "prowlarr.asmussen.tech"
        ];

        "::1" = [
          "qbittorrent.asmussen.tech"
          "shoko.asmussen.tech"
          "sonarr.asmussen.tech"
          "radarr.asmussen.tech"
          "prowlarr.asmussen.tech"
        ];
      };

      home-manager.userModules.bastian = self.homeModuleSets.delta;
    };
}
