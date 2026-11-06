{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.eta = inputs.nixpkgs-stable.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;

      lib = self.libStable;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostEta
    ];
  };

  flake.nixosModules.hostEta =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        # External modules.
        inputs.disko.nixosModules.disko
        inputs.stylix-stable.nixosModules.stylix
        inputs.home-manager-stable.nixosModules.home-manager

        # Host-specific hardware.
        self.diskoConfigurations.hostEta

        # Base modules.
        self.nixosModules.base
        self.nixosModules.language
        self.nixosModules.time
        self.nixosModules.stylix
        self.nixosModules.systemdBoot

        # Nix.
        self.nixosModules.nix
        self.nixosModules.nh

        # Security.
        self.nixosModules.acmeShared
        self.nixosModules.gpg
        self.nixosModules.security
        self.nixosModules.sops
        self.nixosModules.ssh
        self.nixosModules.wireguard

        # Features.
        self.nixosModules.btop
        self.nixosModules.btrfs
        self.nixosModules.preservation
        self.nixosModules.dns
        self.nixosModules.homeManager
        self.nixosModules.networkManager
        self.nixosModules.caddy
        self.nixosModules.primaryMirror
        self.nixosModules.topology
        self.nixosModules.website
        self.nixosModules.covenant
        self.nixosModules.news
        self.nixosModules.remoteBuilder
      ];

      # Support building from x86_64.
      nixpkgs = {
        # buildPlatform.system = "x86_64-linux";
        hostPlatform.system = "aarch64-linux";
      };

      environment.memoryAllocator.provider = "graphene-hardened";
      boot = {
        kernelParams = [
          "slab_nomerge"
          "init_on_alloc=1"
          "init_on_free=1"
          "randomize_kstack_offset=on"
          "vsyscall=none"
          "debugfs=off"
          "lockdown=confidentiality"
        ];

        # Required by the nftables firewall (ct state / ct status dnat rules).
        kernelModules = [
          "nf_conntrack"
          "nft_ct"
          "nf_nat"
        ];

        kernel.sysctl."vm.mmap_rnd_bits" = 32;
      };

      security.lockKernelModules = true;
      networking = {
        hostName = "eta";
        interfaces.enp1s0 = {
          ipv4.addresses = [
            {
              address = inputs.nix-secrets.hosts.eta.ipv4_address;
              prefixLength = 32;
            }
          ];

          ipv6.addresses = [
            {
              address = inputs.nix-secrets.hosts.eta.ipv6_address;
              prefixLength = 64;
            }
          ];
        };

        defaultGateway = {
          address = "172.31.1.1";
          interface = "enp1s0";
        };

        defaultGateway6 = {
          address = "fe80::1";
          interface = "enp1s0";
        };
      };

      topology.self =
        let
          inherit (config.lib.topology) mkConnection;
        in
        {
          hardware.info = "Hetzner Server";
          interfaces = {
            lan = {
              network = "cloud";
              type = "ethernet";
              addresses = [
                inputs.nix-secrets.hosts.eta.ipv4_address
                inputs.nix-secrets.hosts.eta.ipv6_address
              ];
              physicalConnections = [
                (mkConnection "cloudRouter" "eth1")
              ];
            };

            wg0.physicalConnections = [
              (mkConnection "epsilon" "wg0")
              (mkConnection "delta" "wg0")
            ];
          };
        };

      wireguard = {
        enable = true;
        forwardPeers = true;
        ips = [
          "10.10.0.1/24"
          "fd00:10:10::1/64"
        ];
        listenPort = 51820;
        peers = [
          {
            publicKey = inputs.nix-secrets.hosts.epsilon.wg-public-key;
            peerIps = self.nixosConfigurations.epsilon.config.wireguard.ips;
            presharedKeyFile = config.sops.secrets."wireguard/psk-eta-epsilon".path;
          }
          {
            publicKey = inputs.nix-secrets.hosts.delta.wg-public-key;
            peerIps = self.nixosConfigurations.delta.config.wireguard.ips;
            presharedKeyFile = config.sops.secrets."wireguard/psk-eta-delta".path;
          }
          {
            publicKey = inputs.nix-secrets.hosts.mu.wg-public-key;
            allowedIPs = [
              "10.10.0.4/32"
              "fd00:10:10::4/128"
            ];

            presharedKeyFile = config.sops.secrets."wireguard/psk-eta-mu".path;
          }
        ];
      };

      # eta only runs closures built elsewhere.
      nix.settings.max-jobs = lib.mkForce 0;
      btrfs.scrub.fileSystems = [
        "/persist"
        "/nix"
        "/home"
      ];

      persistence = {
        enable = true;
        directories = [
          {
            directory = "/var/lib/chrony";
            user = "chrony";
            group = "chrony";
          }
        ];
      };

      acmeShared = {
        enable = true;
        dkRedirects.enable = true;
      };

      # Keep fallback sites on loopback for local Covenant termination.
      caddy = {
        extended = true;
        openFirewall = true;
        listenAddresses = [ "127.0.0.1" ];
        defaultPort = 8443;
      };

      primaryMirror = {
        enable = true;
        mtlsNames = map (name: "${name}.asmussen.tech") [
          "shoko"
          "qbittorrent"
          "radarr"
          "sonarr"
          "prowlarr"
        ];

        passthroughNames = [
          "asmussen.tech"
          "*.asmussen.tech"
        ]
        ++ config.acmeShared.dkRedirects.domains;
      };

      # Serve epsilon's pushed feed while epsilon is offline.
      newsSync.receive = {
        enable = true;
        authorizedKeys = [ inputs.nix-secrets.hosts.epsilon.news-sync-ssh-public-key ];
      };

      sops.secrets = {
        "wireguard/psk-eta-epsilon" = { };
        "wireguard/psk-eta-delta" = { };
        "wireguard/psk-eta-mu" = { };
        "covenant/smtp-token" = { };
        "covenant/admin-email" = { };
        "covenant/admin-password-hash" = { };
        "covenant/deploy-key" = { };
      };

      services = {
        openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
        chrony = {
          enable = true;
          enableNTS = true;
          servers = [
            "time.cloudflare.com"
            "ntppool1.time.nl"
          ];
        };

        caddy.virtualHosts =
          let
            covenant = config.covenant-extras.domain;
            allowedRedirectHosts = [
              covenant
              "www.${covenant}"
            ]
            ++ config.acmeShared.dkRedirects.domains;
          in
          {
            # Covenant traffic falls through the layer4 routes and terminates here.
            "${covenant}:443" = {
              listenAddresses = [ ];
              extraConfig = ''
                import hsts
                reverse_proxy localhost:${toString config.services.covenant.port}
              '';
            };

            "www.${covenant}:443" = {
              listenAddresses = [ ];
              extraConfig = ''
                import hsts
                redir https://${covenant}{uri} permanent
              '';
            };

            "http://" = {
              listenAddresses = [ ];
              extraConfig = ''
                @allowed_asmussen vars_regexp {host} (?i)^(?:[a-z0-9-]+\.)*asmussen\.tech$
                @allowed_other host ${lib.concatStringsSep " " allowedRedirectHosts}

                redir @allowed_asmussen https://{host}{uri} permanent
                redir @allowed_other https://{host}{uri} permanent
                respond 421
              '';
            };

            # Serve this fallback while epsilon is down or busy.
            "asmussen.tech".extraConfig = ''
              import hsts
              redir /covenant* https://${covenant}/ permanent
            '';

            "www.asmussen.tech".extraConfig = ''
              import hsts
              redir https://asmussen.tech{uri} permanent
            '';

            "jellyfin.asmussen.tech".extraConfig = ''
              import hsts
              respond 503
            '';

            "requests.asmussen.tech".extraConfig = ''
              import hsts
              respond 503
            '';

            # Everything else epsilon serves has no stand-in here.
            "*.asmussen.tech".extraConfig = ''
              import hsts
              respond 421
            '';
          };
      };

      users.users.root.openssh.authorizedKeys.keyFiles = lib.custom.keys.selectSshPaths [
        "ssh-epsilon.pub"
        "ssh-delta.pub"
      ] lib.custom.keys.default;

      environment.systemPackages = [
        pkgs.neovim-minimal
      ];

      home-manager.userModules.bastian = self.homeModuleSets.eta;
    };
}
