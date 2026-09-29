{
  inputs,
  self,
  ...
}:
{
  # Eta uses stable nixpkgs and matching lib for its public host.
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
        self.nixosModules.nginx
        self.nixosModules.nix-serve
        self.nixosModules.primaryMirror
        self.nixosModules.topology
        self.nixosModules.website
        self.nixosModules.covenant
        self.nixosModules.news
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

        # Declare nftables modules because lockKernelModules prevents runtime
        # loading.
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

      # Closures arrive via `just deploy`; eta never builds.
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

      nginx.streamProxy = {
        enable = true;
        stateFile = "/var/lib/primary-mirror/stream-upstream.conf";

        # Terminate Covenant locally; it has no epsilon failover.
        sniRoutes = {
          "covenantofearth.org" = "127.0.0.1:8443";
          "www.covenantofearth.org" = "127.0.0.1:8443";
        };

        # Local vhosts get the client address; epsilon's 443 does not speak PROXY.
        proxyProtocol = {
          enable = true;
          strip = lib.unique (
            [ "${config.primaryMirror.primaryHost}:${toString config.primaryMirror.primaryPort}" ]
            ++ lib.mapAttrsToList (_: route: route.primaryAddress) config.primaryMirror.sniRoutes
          );
        };
      };

      primaryMirror = {
        enable = true;
        fallbackAddress = "127.0.0.1:8443";
        healthCheckHost = "cache.asmussen.tech";
        healthCheckPath = "/nix-cache-info";
        sniRoutes = {
          "jellyfin.asmussen.tech".primaryAddress = "10.10.0.2:443";
          "requests.asmussen.tech".primaryAddress = "10.10.0.2:443";
        };

        busyAuthorizedKeys = [ inputs.nix-secrets.hosts.epsilon.primary-busy-ssh-public-key ];
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
      };

      nix-serve-extras.exposePublicly = false;
      website-extras.exposePublicly = false;

      # Issue a separate Cloudflare DNS-01 certificate with www as a SAN.
      security.acme.certs."covenantofearth.org" = {
        extraDomainNames = [ "www.covenantofearth.org" ];
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
        inherit (config.services.nginx) group;
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

        nginx = {
          appendHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            map $scheme $hsts_header {
                https   "max-age=63072000; includeSubDomains; preload";
            }

            add_header Strict-Transport-Security $hsts_header always;

            # Client address from the stream hop's PROXY header.
            set_real_ip_from 127.0.0.1;
            real_ip_header proxy_protocol;
          '';

          virtualHosts =
            let
              acmeDir = "/var/lib/acme/asmussen.tech";
              fallbackListen = {
                addr = "127.0.0.1";
                port = 8443;
                ssl = true;
                proxyProtocol = true;
              };

              sslConfig = ''
                ssl_certificate ${acmeDir}/fullchain.pem;
                ssl_certificate_key ${acmeDir}/key.pem;
              '';

              covenantSsl =
                let
                  dir = "/var/lib/acme/${config.covenant-extras.domain}";
                in
                ''
                  ssl_certificate ${dir}/fullchain.pem;
                  ssl_certificate_key ${dir}/key.pem;
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
                locations = {
                  "/" = {
                    proxyPass = "http://localhost:${toString config.services.website.port}";
                    proxyWebsockets = true;
                  };

                  # Match epsilon's legacy Covenant redirect.
                  "/covenant".return = "301 https://${config.covenant-extras.domain}/";
                };
              };

              # Set explicit certificate paths; useACMEHost does not handle
              # custom listens.
              ${config.covenant-extras.domain} = {
                listen = [ fallbackListen ];
                extraConfig = covenantSsl;
                locations."/" = {
                  proxyPass = "http://localhost:${toString config.services.covenant.port}";
                  # Overwrite, not append: covenant rate-limits on this header.
                  extraConfig = "proxy_set_header X-Forwarded-For $remote_addr;";
                };
              };

              "www.${config.covenant-extras.domain}" = {
                listen = [ fallbackListen ];
                extraConfig = covenantSsl;
                locations."/".return = "301 https://${config.covenant-extras.domain}$request_uri";
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
        "ssh-epsilon.pub"
        "ssh-delta.pub"
      ] lib.custom.keys.default;

      environment.systemPackages = [
        pkgs.neovim-minimal
      ];

      home-manager.userModules.bastian = self.homeModuleSets.eta;
    };
}
