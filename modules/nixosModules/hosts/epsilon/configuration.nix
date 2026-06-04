{
  inputs,
  self,
  ...
}:
{
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

  flake.nixosModules.hostEpsilon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkForce;
    in
    {
      imports = [
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
        self.nixosModules.nix
        self.nixosModules.nh
        self.nixosModules.eh

        # Security.
        self.nixosModules.acmeShared
        self.nixosModules.gpg
        self.nixosModules.security
        self.nixosModules.sops
        self.nixosModules.ssh
        self.nixosModules.luksFido2
        self.nixosModules.yubiKey
        self.nixosModules.preservation
        self.nixosModules.wireguard

        # Features.
        self.nixosModules.japanese
        self.nixosModules.bluetooth
        self.nixosModules.btop
        self.nixosModules.btrfs
        self.nixosModules.ccache
        self.nixosModules.gaming
        self.nixosModules.goxlr
        self.nixosModules.homeManager
        self.nixosModules.jellyfin
        self.nixosModules.seerr
        self.nixosModules.qbittorrent
        self.nixosModules.servarr
        self.nixosModules.syncthing
        self.nixosModules.primaryBusy
        self.nixosModules.monero
        self.nixosModules.dns
        self.nixosModules.networkManager
        self.nixosModules.nginx
        self.nixosModules.nix-serve
        self.nixosModules.nvidia
        self.nixosModules.topology
        self.nixosModules.virtualisation
        self.nixosModules.website
        self.nixosModules.winapps
        self.nixosModules.arcticVault
        self.nixosModules.pia
        self.nixosModules.forgejoRunner

        # Host-specific hardware.
        self.diskoConfigurations.hostEpsilon

        # External modules.
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        inputs.nix-index-database.nixosModules.nix-index

        # Hardware-specific.
        inputs.nixos-hardware.nixosModules.common-cpu-amd
      ];

      networking.hostName = "epsilon";
      topology.self =
        let
          inherit (config.lib.topology) mkConnection;
        in
        {
          hardware.info = "AMD Ryzen Desktop, NVIDIA GPU";
          interfaces = {
            lan = {
              network = "home";
              type = "ethernet";
              addresses = [ "192.168.1.64" ];
              physicalConnections = [
                (mkConnection "homeRouter" "eth1")
              ];
            };

            wg0.physicalConnections = [
              (mkConnection "eta" "wg0")
            ];
          };

          services.syncthing = {
            name = "Syncthing";
            icon = "services.syncthing";
          };
        };

      services = {
        ollama = {
          enable = true;
          package = pkgs.ollama-cuda;
        };

        meilisearch.masterKeyFile = config.sops.secrets."meilisearch/master-key".path;
      };

      sops.secrets = {
        "wireguard/psk-eta-epsilon" = { };
        "meilisearch/master-key" = { };
      };

      # /etc/machine-id is persisted by the preservation module in initrd.
      # The commit unit only applies to transient machine-id on tmpfs.
      systemd.services.systemd-machine-id-commit.enable = false;

      persistence = {
        enable = true;

        # System state that must survive reboot.
        directories = [
          "/var/lib/acme" # ACME/Let's Encrypt certificates.
          "/var/lib/AccountsService" # User list / icons.
          "/var/lib/bluetooth"
          "/var/lib/power-profiles-daemon"
          {
            directory = "/var/lib/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
          }
          "/var/lib/private/meilisearch"
          "/var/lib/qBittorrent"
          {
            directory = "/var/lib/sonarr";
            user = "sonarr";
            group = "sonarr";
          }
          {
            directory = "/var/lib/radarr";
            user = "radarr";
            group = "radarr";
          }
          "/var/lib/systemd/coredump"
          "/var/lib/private/gitea-runner" # Forgejo runner state.
          "/var/lib/private/prowlarr"
          "/var/lib/private/seerr"
          "/var/lib/private/ollama"
          {
            directory = "/var/cache/ccache";
            user = "root";
            group = "nixbld";
            mode = "0770";
          }
        ];

        directoriesWithMode = {
          "/var/lib/private" = "0700";
          "/var/cache/jellyfin" = "0755";
        };

        files = [
          # Better entropy at boot.
          {
            file = "/var/lib/systemd/random-seed";
            how = "symlink";
          }
        ];

        user = {
          directories = [
            # XDG user dirs.
            "Desktop"
            "Documents"
            "Downloads"
            "Music"
            "Pictures"
            "Public"
            "Templates"
            "Videos"

            # Personal.
            "Windows"
            "Projects"
            "dotfiles"
            "nix-secrets"
            "go"
            "Games"
            "Postman"

            # App state / configs not fully managed by HM.
            ".config/sops" # VERY important!
            ".config/libreoffice"
            ".config/vesktop"
            ".config/spotify"
            ".config/teams-for-linux"
            ".mozilla"
            ".password-store"
            ".pki"
            ".ssh"

            ".local/share/bottles"
            ".local/share/containers"
            ".local/share/direnv"
            ".local/share/flatpak"
            ".local/share/gopass"
            ".local/share/goxlr-utility"
            ".local/share/lutris"
            ".local/share/nvim"
            ".local/share/opencode"
            ".local/share/Steam"
            ".local/share/umu"
            ".local/share/zoxide"
            ".local/share/zsh"

            ".local/state/home-manager"
            ".local/state/nix"
            ".local/state/nvim"
            ".local/state/wireplumber"
            ".local/state/mpv"
          ];

          directoriesWithMode = {
            ".gnupg" = "0700";
            ".local/share/keyrings" = "0700";
          };

          cache.directories = [
            ".cache/direnv"
            ".cache/spotify/Storage"
          ];
        };
      };

      wireguard = {
        enable = true;
        ips = [
          "10.10.0.2/24"
          "fd00:10:10::2/64"
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
            presharedKeyFile = config.sops.secrets."wireguard/psk-eta-epsilon".path;
          }
        ];
      };

      acmeShared = {
        enable = true;
        dkRedirects.enable = true;
      };

      ssh.fail2ban.enable = false;

      nix-serve-extras.bindAddress = "10.10.0.2";
      nginx = {
        acme.sharedHost = "asmussen.tech";

        reverseProxies = {
          jellyfin = {
            enable = true;
            domain = "jellyfin.asmussen.tech";
            location = "/";
            upstream = "http://localhost:8096";
            ssl = {
              dnsProvider = "cloudflare";
              environmentFile = config.sops.templates."cloudflare-acme-env".path;
            };
          };

          shoko = {
            enable = true;
            domain = "shoko.asmussen.tech";
            location = "/";
            upstream = "http://localhost:8111";
            mtls = {
              enable = true;
              caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
              localhostBypass = true;
            };
          };

          qbittorrent = {
            enable = true;
            domain = "qbittorrent.asmussen.tech";
            location = "/";
            upstream = "http://localhost:${toString config.services.qbittorrent.webuiPort}";
            mtls = {
              enable = true;
              caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
              localhostBypass = true;
            };
          };

          radarr = {
            enable = true;
            domain = "radarr.asmussen.tech";
            location = "/";
            upstream = "http://localhost:${toString config.services.radarr.settings.server.port}";
            mtls = {
              enable = true;
              caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
              localhostBypass = true;
            };
          };

          sonarr = {
            enable = true;
            domain = "sonarr.asmussen.tech";
            location = "/";
            upstream = "http://localhost:${toString config.services.sonarr.settings.server.port}";
            mtls = {
              enable = true;
              caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
              localhostBypass = true;
            };
          };

          seerr = {
            enable = true;
            domain = "requests.asmussen.tech";
            location = "/";
            upstream = "http://localhost:${toString config.services.seerr.port}";
            ssl = {
              dnsProvider = "cloudflare";
              environmentFile = config.sops.templates."cloudflare-acme-env".path;
            };
          };

          prowlarr = {
            enable = true;
            domain = "prowlarr.asmussen.tech";
            location = "/";
            upstream = "http://localhost:${toString config.services.prowlarr.settings.server.port}";
            mtls = {
              enable = true;
              caCertificate = lib.custom.keys.selectCertPath "mtls-ca.crt" lib.custom.keys.default;
              localhostBypass = true;
            };
          };
        };
      };

      services = {
        nginx = {
          # 5 login attempts/min per IP; burst allows a brief spike before
          # dropping requests (nodelay means excess reqs are rejected, not queued).
          appendHttpConfig = ''
            limit_req_zone $binary_remote_addr zone=jellyfin_auth:10m rate=5r/m;
            limit_req_zone $binary_remote_addr zone=seerr_auth:10m rate=5r/m;
          '';

          virtualHosts = {
            "www.asmussen.tech" = {
              useACMEHost = "asmussen.tech";
              forceSSL = true;
              locations."/".return = "301 https://asmussen.tech$request_uri";
            };

            # Redirect legacy path to subdomain for existing bookmarks.
            "asmussen.tech".locations."/jellyfin".return = "301 https://jellyfin.asmussen.tech/";

            "jellyfin.asmussen.tech".locations = {
              # Pre-auth endpoints no remote client needs. The LAN-only gates on
              # these are bypassed because eta's TLS passthrough makes every
              # internet request look WireGuard-local to epsilon.
              "~* ^/Users/ForgotPassword".return = "403";
              "~* ^/Users/Public".return = "403";
              "~* ^/QuickConnect".return = "403";
              "~* ^/Startup".return = "403";
              "~* ^/ClientLog".return = "403";

              "~* ^/Users/AuthenticateByName" = {
                proxyPass = "http://localhost:8096";
                extraConfig = "limit_req zone=jellyfin_auth burst=3 nodelay;";
              };
            };

            "requests.asmussen.tech".locations."~* ^/api/v1/auth/(local|jellyfin)" = {
              proxyPass = "http://localhost:${toString config.services.seerr.port}";
              extraConfig = "limit_req zone=seerr_auth burst=3 nodelay;";
            };
          };
        };

        openssh.openFirewall = false;
      };

      qbittorrent = {
        networkInterface = config.pia.interface;
        categories =
          let
            animePath = "/srv/media/torrents/complete/anime";
          in
          {
            linux-isos = { };

            # Manual / Shoko-managed anime library. Monitored by no *arr client.
            anime.path = animePath;
            shows = { };
            movies = { };

            # Sonarr/Radarr anime grabs land here but share the anime save path,
            # so Shoko still catalogs them while the *arr clients only ever
            # enumerate their own downloads instead of the whole seeding library.
            sonarr-anime.path = animePath;
            radarr-anime.path = animePath;
          };
      };

      pia = {
        enable = true;
        region = "nl_amsterdam";
        boundServices = [ "qbittorrent" ];
        portSync.passwordFile = config.qbittorrent.webuiPasswordFile;
      };

      servarr.enable = true;
      seerr.enable = true;

      # Resolve qbittorrent to loopback so the browser hits the local mTLS proxy
      # instead of going out through eta (bypasses public DNS and the untrusted hop).
      networking = {
        # Never roams, don't let DHCP DNS shadow the global DoT config.
        networkmanager.settings.connection = {
          "ipv4.ignore-auto-dns" = true;
          "ipv6.ignore-auto-dns" = true;
        };

        hosts = {
          "127.0.0.1" = [
            "qbittorrent.asmussen.tech"
            "radarr.asmussen.tech"
            "shoko.asmussen.tech"
            "sonarr.asmussen.tech"
            "prowlarr.asmussen.tech"
          ];

          "::1" = [
            "qbittorrent.asmussen.tech"
            "radarr.asmussen.tech"
            "shoko.asmussen.tech"
            "sonarr.asmussen.tech"
            "prowlarr.asmussen.tech"
          ];
        };

        # Allow WireGuard peers (eta, delta) to reach proxied services on epsilon.
        firewall.interfaces.wg0.allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.nix-serve.port
          config.services.website.port
          443 # nginx, WG peers reach epsilon directly
        ];
      };

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

      winapps.enable = true;

      primaryBusy.enable = true;
      btrfs.scrub.fileSystems = [
        "/persist"
        "/srv/media"
        "/srv/arctic-vault"
      ];

      arcticVault = {
        enable = true;
        calendar = "weekly";
        timestampFormat = "%Y-W%V";
        sources = [
          "dotfiles"
          "nix-secrets"
          ".password-store"
        ];

        recipients = map (f: lib.strings.trim (builtins.readFile f)) lib.custom.keys.default.agePaths;
      };

      home-manager.userModules.bastian = self.homeModuleSets.epsilon;

      specialisation.safeMode.configuration = {
        system.nixos.tags = [ "safe-mode" ];

        boot.kernelPackages = mkForce pkgs.linuxPackages_latest;

        wireguard.enable = mkForce false;
        pia.enable = mkForce false;
        acmeShared.enable = mkForce false;
        winapps.enable = mkForce false;

        virtualisation.podman.enable = mkForce false;

        qbittorrent.enable = mkForce false;
        servarr.enable = mkForce false;

        nginx.enable = mkForce false;

        seerr.enable = mkForce false;

        services = {
          jellyfin.enable = mkForce false;
          meilisearch.enable = mkForce false;
          shoko.enable = mkForce false;
          syncthing.enable = mkForce false;
          nix-serve.enable = mkForce false;
          website.enable = mkForce false;
          ollama.enable = mkForce false;
        };
      };
    };
}
