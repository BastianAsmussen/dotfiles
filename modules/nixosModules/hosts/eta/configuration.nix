{
  inputs,
  self,
  ...
}: {
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

  flake.nixosModules.hostEta = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.systemdBoot
      self.nixosModules.language
      self.nixosModules.stylix

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Security
      self.nixosModules.security
      self.nixosModules.sops
      self.nixosModules.gpg
      self.nixosModules.ssh
      self.nixosModules.wireguard

      # Features
      self.nixosModules.btrfs
      self.nixosModules.homeManager
      self.nixosModules.remoteBuilder
      self.nixosModules.primaryMirror
      self.nixosModules.networkManager
      self.nixosModules.nginx
      self.nixosModules.nix-serve
      self.nixosModules.topology
      self.nixosModules.website

      # Host-specific hardware
      self.diskoConfigurations.hostEta

      # External modules
      inputs.disko.nixosModules.disko
      inputs.stylix.nixosModules.stylix
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

      kernel.sysctl."vm.mmap_rnd_bits" = 32;
    };

    security.lockKernelModules = true;

    networking = {
      hostName = "eta";

      interfaces.enp1s0.ipv6.addresses = [
        {
          address = inputs.nix-secrets.hosts.eta.ipv6_address;
          prefixLength = 64;
        }
      ];

      defaultGateway6 = {
        address = "fe80::1";
        interface = "enp1s0";
      };
    };

    topology.self = let
      inherit (config.lib.topology) mkConnection;
    in {
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
      ips = ["10.10.0.1/24" "fd00:10:10::1/64"];
      listenPort = 51820;
      peers = [
        {
          publicKey = inputs.nix-secrets.hosts.epsilon.wg-public-key;
          allowedIPs = ["10.10.0.2/32" "fd00:10:10::2/128"];
          presharedKeyFile = config.sops.secrets."wireguard/psk-eta-epsilon".path;
        }
        {
          publicKey = inputs.nix-secrets.hosts.delta.wg-public-key;
          allowedIPs = ["10.10.0.3/32" "fd00:10:10::3/128"];
          presharedKeyFile = config.sops.secrets."wireguard/psk-eta-delta".path;
        }
      ];
    };

    # Eta is not fit for building, offload everything to Epsilon.
    # If Epsilon is unreachable, builds fail rather than running locally.
    nix.settings.max-jobs = lib.mkForce 0;

    btrfs.scrub.fileSystems = ["/"];

    nginx = {
      streamProxy = {
        enable = true;
        stateFile = "/var/lib/primary-mirror/stream-upstream.conf";
      };

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
    };

    primaryMirror = {
      enable = true;

      fallbackAddress = "127.0.0.1:8443";
      healthCheckHost = "cache.asmussen.tech";
      healthCheckPath = "/nix-cache-info";

      sniRoutes."jellyfin.asmussen.tech".primaryAddress = "10.10.0.2:8920";
    };

    sops = {
      secrets = {
        "cloudflare-api-token" = {};
        "wireguard/psk-eta-epsilon" = {};
        "wireguard/psk-eta-delta" = {};
      };

      templates."cloudflare-acme-env" = {
        owner = "acme";
        content = "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
      };
    };

    users.users.acme.extraGroups = ["keys"];
    security.acme = {
      acceptTerms = true;
      defaults.email = config.preferences.user.email;
      certs."asmussen.tech" = {
        inherit (config.services.nginx) group;

        extraDomainNames = ["*.asmussen.tech"];
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
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
          add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
        '';

        virtualHosts = let
          acmeDir = "/var/lib/acme/asmussen.tech";
          fallbackListen = [
            {
              addr = "127.0.0.1";
              port = 8443;
              ssl = true;
            }
          ];

          sslConfig = ''
            ssl_certificate ${acmeDir}/fullchain.pem;
            ssl_certificate_key ${acmeDir}/key.pem;
          '';
        in {
          "asmussen.tech" = {
            listen = fallbackListen;
            extraConfig = sslConfig;
            locations."/" = {
              proxyPass = "http://localhost:${toString config.services.website.port}";
              proxyWebsockets = true;
            };
          };

          "jellyfin.asmussen.tech" = {
            listen = fallbackListen;
            extraConfig = sslConfig;
            locations."/".return = "503";
          };

          "cache.asmussen.tech" = {
            listen = fallbackListen;
            extraConfig = sslConfig;
            locations."/".proxyPass = "http://localhost:${toString config.services.nix-serve.port}";
          };
        };
      };
    };

    users.users.root.openssh.authorizedKeys.keyFiles =
      lib.custom.keys.selectSshPaths ["ssh-epsilon.pub" "ssh-delta.pub"] lib.custom.keys.default;

    environment.systemPackages = [
      pkgs.neovim-minimal
    ];

    home-manager.userModules.bastian = self.homeModuleSets.eta;
  };
}
