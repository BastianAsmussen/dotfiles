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
        self.nixosModules.language
        self.nixosModules.lanzaboote
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
        self.nixosModules.ssh
        self.nixosModules.tor
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
        self.nixosModules.youtubeArchive
        self.nixosModules.seerr
        self.nixosModules.qbittorrent
        self.nixosModules.servarr
        self.nixosModules.syncthing
        self.nixosModules.primaryBusy
        self.nixosModules.monero
        self.nixosModules.dns
        self.nixosModules.networkManager
        self.nixosModules.nginx
        self.nixosModules.router
        self.nixosModules.nix-serve
        self.nixosModules.nvidia
        self.nixosModules.topology
        self.nixosModules.virtualisation
        self.nixosModules.website
        self.nixosModules.news
        self.nixosModules.winapps
        self.nixosModules.arcticVault
        self.nixosModules.pia
        self.nixosModules.forgejoRunner
        self.nixosModules.searx
        self.nixosModules.deepseekHarness

        # Host-specific hardware.
        self.diskoConfigurations.hostEpsilon

        # External modules.
        inputs.egg-mouse-config.nixosModules.default
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

          services = {
            syncthing = {
              name = "Syncthing";
              icon = "services.syncthing";
            };

            monerod = {
              name = "Monero";
              icon = "services.monerod";
            };
          };
        };

      jellyfin.enable = true;
      searx.enable = true;
      youtubeArchive = {
        enable = true;
        uid = 984;

        # Run once per day at 04:00.
        schedule = "04:00";
        channels = {
          Veritasium = "https://www.youtube.com/@veritasium";
          fern = "https://www.youtube.com/@fern-tv";
        };
      };

      services = {
        ollama = {
          enable = true;
          package = pkgs.ollama-cuda;
        };

        meilisearch.masterKeyFile = config.sops.secrets."meilisearch/master-key".path;

        website.port = 8083;
      };

      sops = {
        secrets = {
          "wireguard/psk-eta-epsilon" = { };
          "meilisearch/master-key" = { };

          # Icotera router: web/admin password and WiFi WPA passphrase,
          # consumed by the `router` module when rendering/pushing config.
          "router/admin-password" = { };
          "router/wifi-passphrase" = { };

          "services/searx/secret-key" = { };
        };
      };

      persistence = {
        enable = true;

        # System state that must survive reboot.
        directories = [
          "/var/lib/acme" # ACME/Let's Encrypt certificates.
          "/var/lib/AccountsService" # User list / icons.
          "/var/lib/bluetooth"
          "/var/lib/power-profiles-daemon"
          "/var/lib/private/meilisearch"
          {
            directory = "/var/lib/chrony";
            user = "chrony";
            group = "chrony";
          }
          "/var/lib/qBittorrent"
          "/var/lib/dsh" # DSH_HOME: dsh profiles, storages, UI-set credentials.
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
            # Keep a stable entry-guard set instead of selecting new guards on
            # every reboot.
            directory = "/var/lib/tor";
            user = "tor";
            group = "tor";
            mode = "0700";
          }
          {
            directory = "/var/cache/ccache";
            user = "root";
            group = "nixbld";
            mode = "0770";
          }
        ];

        directoriesWithMode = {
          "/var/lib/private" = "0700";

          # Secure Boot keys (lanzaboote pkiBundle). Root tmpfs is wiped every
          # boot, so this must persist or the next rebuild can't sign the boot
          # chain and the machine becomes unbootable.
          "/var/lib/sbctl" = "0700";
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
            ".config/sops-nix"
            ".config/libreoffice"
            ".config/Signal"
            ".config/vesktop"
            ".config/spotify"
            ".config/teams-for-linux"
            ".mozilla"
            ".password-store"
            ".pki"
            ".ssh"
            ".dsh"

            ".local/share/bottles"
            ".local/share/containers"
            ".local/share/direnv"
            ".local/share/flatpak"
            ".local/share/gopass"
            ".local/share/goxlr-utility"
            ".local/share/lutris"
            ".local/share/nvim"
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
            ".tor project" = "0700";
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

          dsh = {
            enable = true;
            domain = config.deepseek-harness.trustedHost;
            location = "/";
            upstream = "http://localhost:${toString config.deepseek-harness.port}";
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
      deepseek-harness = {
        enable = true;
        checkouts."/projects".source = "/home/bastian/Projects";
      };

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
            "dsh.asmussen.tech"
          ];

          "::1" = [
            "qbittorrent.asmussen.tech"
            "radarr.asmussen.tech"
            "shoko.asmussen.tech"
            "sonarr.asmussen.tech"
            "prowlarr.asmussen.tech"
            "dsh.asmussen.tech"
          ];
        };

        # Allow WireGuard peers (eta, delta) to reach proxied services on epsilon.
        firewall.interfaces.wg0.allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.nix-serve.port
          config.services.website.port
          443 # nginx, WG peers reach epsilon directly
        ];
      };

      preferences = {
        noctalia.idleEnabled = false;
        monitors = {
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
      };

      monero = {
        node = {
          enable = true;
          uid = 986;
          gid = 983;
        };

        mining = {
          enable = false;
          pool = "pool.hashvault.pro:80";
          wallet = self.preferences.monero-wallet;
          maxUsagePercentage = 25;
        };
      };

      winapps.enable = true;

      programs.egg-mouse-config.enable = true;

      primaryBusy.enable = true;

      # Aggregates and assesses the global news feed locally (Ollama is here),
      # serves it to epsilon's own website, and pushes copies to eta over
      # WireGuard SSH so asmussen.tech/news works while epsilon is offline.
      newsSync.push.enable = true;

      # While a gamemode session is active (the user is gaming) the news
      # daemon must not aggregate or hit Ollama: gamemode's start/end hooks
      # toggle the /run/news/pause marker that news-busy.path reacts to via
      # inotify.
      primaryBusy = {
        gamemodeStartHooks = [
          "${lib.getExe' pkgs.coreutils "touch"} /run/news/pause"
        ];

        gamemodeEndHooks = [
          "${lib.getExe' pkgs.coreutils "rm"} -f /run/news/pause"
        ];
      };

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

      # Declarative Icotera i4850-20 router config. Mirrors the device's
      # current state, so a push regenerates its backup faithfully; edit these
      # options (not the web panel) and run `just router-restore` to apply.
      # Secrets live in sops (router/admin-password, router/wifi-passphrase).
      router = {
        enable = true;
        adminPasswordFile = config.sops.secrets."router/admin-password".path;
        dns = [ "192.168.1.254" ];

        wifi = {
          ssid = "GangnamStyle";
          passphraseFile = config.sops.secrets."router/wifi-passphrase".path;
        };

        dhcp.staticLeases = [
          {
            hostname = "epsilon";
            mac = "c8:7f:54:66:ff:72";
            ip = "192.168.1.64";
          }
        ];

        # Present on the device but disabled; kept here so they round-trip and
        # can be flipped on declaratively when needed.
        portForwards = [
          {
            name = "SSH";
            internalClient = "192.168.1.64";
            externalPort = 22;
            enable = false;
          }
          {
            name = "HTTPS";
            internalClient = "192.168.1.64";
            externalPort = 443;
            enable = false;
          }
          {
            name = "HTTP";
            internalClient = "192.168.1.64";
            externalPort = 80;
            enable = false;
          }
        ];
      };

      home-manager.userModules.bastian = self.homeModuleSets.epsilon;

      specialisation.safeMode.configuration = {
        system.nixos.tags = [ "safe-mode" ];

        boot.kernelPackages = mkForce pkgs.linuxPackages_latest;

        wireguard.enable = mkForce false;
        pia.enable = mkForce false;
        acmeShared.enable = mkForce false;
        winapps.enable = mkForce false;

        jellyfin.enable = mkForce false;
        youtubeArchive.enable = mkForce false;

        qbittorrent.enable = mkForce false;
        servarr.enable = mkForce false;
        seerr.enable = mkForce false;

        nginx.enable = mkForce false;

        primaryBusy.enable = mkForce false;
        monero.node.enable = mkForce false;
        arcticVault.enable = mkForce false;

        newsSync.push.enable = mkForce false;

        virtualisation = {
          podman.enable = mkForce false;
          libvirtd.enable = mkForce false;
        };

        services = {
          gitea-actions-runner.instances.epsilon.enable = mkForce false;

          syncthing.enable = mkForce false;
          nix-serve.enable = mkForce false;
          website.enable = mkForce false;
          news.enable = mkForce false;
          ollama.enable = mkForce false;
          tor.enable = mkForce false;
        };
      };
    };
}
