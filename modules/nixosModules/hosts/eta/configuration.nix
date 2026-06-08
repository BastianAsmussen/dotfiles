{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.eta = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

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
        inputs.stylix.nixosModules.stylix

        # Host-specific hardware.
        self.diskoConfigurations.hostEta

        # Base modules.
        self.nixosModules.base
        self.nixosModules.language
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
        self.nixosModules.homeManager
        self.nixosModules.networkManager
        self.nixosModules.nginx
        self.nixosModules.nix-serve
        self.nixosModules.primaryMirror
        self.nixosModules.remoteBuilder
        self.nixosModules.topology
        self.nixosModules.website
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
        # Must be declared here because lockKernelModules prevents runtime loading.
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

      # Eta is not fit for building, offload everything to Epsilon.
      # If Epsilon is unreachable, builds fail rather than running locally.
      nix.settings.max-jobs = lib.mkForce 0;
      btrfs.scrub.fileSystems = [
        "/persist"
        "/nix"
        "/home"
      ];

      persistence = {
        enable = true;
        directories = [
          "/var/lib/acme"
          {
            directory = "/var/lib/primary-mirror";
            user = "root";
            group = "builder";
            mode = "0775";
          }
        ];
      };

      acmeShared = {
        enable = true;
        dkRedirects.enable = true;
      };

      nginx.streamProxy = {
        enable = true;
        stateFile = "/var/lib/primary-mirror/stream-upstream.conf";
      };

      primaryMirror = {
        enable = true;
        fallbackAddress = "127.0.0.1:8443";
        healthCheckHost = "cache.asmussen.tech";
        healthCheckPath = "/nix-cache-info";
        sniRoutes."jellyfin.asmussen.tech".primaryAddress = "10.10.0.2:443";
        sniRoutes."requests.asmussen.tech".primaryAddress = "10.10.0.2:443";
        busyAuthorizedKeys = [ inputs.nix-secrets.hosts.epsilon.primary-busy-ssh-public-key ];
      };

      sops.secrets = {
        "wireguard/psk-eta-epsilon" = { };
        "wireguard/psk-eta-delta" = { };
        "wireguard/psk-eta-mu" = { };
      };

      nix-serve-extras.exposePublicly = false;
      website-extras.exposePublicly = false;
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

        nginx = {
          appendHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            map $scheme $hsts_header {
                https   "max-age=63072000; includeSubDomains; preload";
            }

            add_header Strict-Transport-Security $hsts_header always;
          '';

          virtualHosts =
            let
              acmeDir = "/var/lib/acme/asmussen.tech";
              fallbackListen = {
                addr = "127.0.0.1";
                port = 8443;
                ssl = true;
              };

              sslConfig = ''
                ssl_certificate ${acmeDir}/fullchain.pem;
                ssl_certificate_key ${acmeDir}/key.pem;
              '';
            in
            {
              "_" = {
                listen = [
                  (
                    fallbackListen
                    // {
                      extraParameters = [ "default_server" ];
                    }
                  )
                ];

                extraConfig = sslConfig;
                locations."/".return = "421";
              };

              "asmussen.tech" = {
                listen = [ fallbackListen ];
                extraConfig = sslConfig;
                locations."/" = {
                  proxyPass = "http://localhost:${toString config.services.website.port}";
                  proxyWebsockets = true;
                };
              };

              "jellyfin.asmussen.tech" = {
                listen = [ fallbackListen ];
                extraConfig = sslConfig;
                locations."/".return = "503";
              };

              "requests.asmussen.tech" = {
                listen = [ fallbackListen ];
                extraConfig = sslConfig;
                locations."/".return = "503";
              };

              "cache.asmussen.tech" = {
                listen = [ fallbackListen ];
                extraConfig = sslConfig;
                locations."/".proxyPass = "http://localhost:${toString config.services.nix-serve.port}";
              };
            };
        };
      };

      users.users.root.openssh.authorizedKeys.keyFiles = lib.custom.keys.selectSshPaths [
        "ssh-yubikey.pub"
      ] lib.custom.keys.default;

      environment.systemPackages = [
        pkgs.neovim-minimal
      ];

      home-manager.userModules.bastian = self.homeModuleSets.eta;
    };
}
