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
        self.nixosModules.worldmonitor

        # Host-specific hardware.
        self.diskoConfigurations.hostEpsilon

        # External modules.
        inputs.egg-mouse-config.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.stylix.nixosModules.stylix
        inputs.nix-index-database.nixosModules.nix-index
        inputs.home-manager.nixosModules.home-manager

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

      # Stop Ollama during games to free its idle VRAM.
      gamemode.pauseUnits = [ "ollama.service" ];

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
          "services/restic/vault-password" = { };
          "wireguard/psk-eta-epsilon" = { };
          "meilisearch/master-key" = { };

          # Router admin and WiFi secrets used to render and push configuration.
          "router/admin-password" = { };
          "router/wifi-passphrase" = { };

          "services/searx/secret-key" = { };

          # Provide upstream API keys and Ollama settings as a dotenv file.
          "worldmonitor/api-keys" = {
            sopsFile = "${toString inputs.nix-secrets}/hosts/epsilon-worldmonitor.env";
            format = "dotenv";
            key = "";
            restartUnits = [
              "worldmonitor-relay.service"
              "worldmonitor-sidecar.service"
            ];
          };
        };
      };

      persistence = {
        enable = true;

        # System state that must survive reboot.
        directories = [
          "/var/lib/AccountsService" # User list / icons.
          "/var/lib/bluetooth"
          "/var/lib/power-profiles-daemon"
          "/var/lib/private/meilisearch"
          {
            directory = "/var/lib/chrony";
            user = "chrony";
            group = "chrony";
          }
          "/var/lib/dsh" # DSH_HOME: dsh profiles, storages, UI-set credentials.
          "/var/lib/systemd/coredump"
          "/var/lib/private/ollama"
        ];

        directoriesWithMode = {
          "/var/lib/private" = "0700";

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
            ".config/libreoffice"
            ".config/Signal"
            ".config/vesktop"
            ".config/teams-for-linux"
            ".pki"
            ".dsh"

            ".local/share/bottles"
            ".local/share/containers"
            ".local/share/flatpak"
            ".local/share/goxlr-utility"

            # No imported home module owns this zsh history path.
            ".local/share/zsh"
            ".local/share/lutris"
            ".local/share/Steam"
            ".local/share/umu"

            ".local/state/home-manager"
            ".local/state/nix"
            ".local/state/wireplumber"
            ".local/state/mpv"
          ];

          directoriesWithMode = {
            ".local/share/keyrings" = "0700";
            ".tor project" = "0700";
          };
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

          worldmonitor = {
            enable = true;
            domain = config.worldmonitor.trustedHost;
            location = "/";
            upstream = "http://localhost:${toString config.worldmonitor.port}";
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
          # Allow 5 login attempts per minute per IP; reject bursts with
          # nodelay.
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

            # Preserve legacy bookmarks; Covenant now lives at its domain root.
            "asmussen.tech".locations = {
              "/jellyfin".return = "301 https://jellyfin.asmussen.tech/";
              "/covenant".return = "301 https://covenantofearth.org/";
            };

            "jellyfin.asmussen.tech".locations = {
              # Block pre-auth endpoints exposed by eta's TLS passthrough.
              "~* ^/Users/ForgotPassword".return = "403";
              "~* ^/QuickConnect".return = "403";
              "~* ^/Startup".return = "403";
              "~* ^/ClientLog".return = "403";

              "~* ^/Users/Public".extraConfig = ''
                default_type application/json;
                return 200 "[]";
              '';

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

            # Share anime with Shoko without exposing the whole seeding library.
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

      servarr = {
        enable = true;

        prowlarr = {
          # Both sit behind Cloudflare.
          flaresolverrIndexers = [
            "1337x"
            "EZTV"
          ];

          # AnimeTosho's long tracker URLs break Prowlarr's proxy links.
          torrentFileIndexers = [ "AnimeTosho" ];
        };

        # Seerr skips root overrides for admins; reconcile admin anime requests.
        radarr.syncAnimeRoot = true;

        # Keep both *arr copies of the WebUI password synchronized.
        downloadClient = {
          syncCredentials = true;

          username = config.qbittorrent.webuiUsername;
          passwordFile = config.qbittorrent.webuiPasswordFile;
        };
      };
      seerr.enable = true;
      deepseek-harness = {
        enable = true;
        # Pin ids outside the drifting 98x system-group band.
        uid = 600;
        gid = 600;
        checkouts."/projects".source = "/home/bastian/Projects";
      };
      worldmonitor = {
        enable = true;
        # Inject provider keys and local Ollama settings into sidecar, relay and
        # seeders.
        extraEnvironmentFiles = [ config.sops.secrets."worldmonitor/api-keys".path ];
      };

      # Use the local mTLS proxy instead of routing qBittorrent through eta.
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
            "worldmonitor.asmussen.tech"
          ];

          "::1" = [
            "qbittorrent.asmussen.tech"
            "radarr.asmussen.tech"
            "shoko.asmussen.tech"
            "sonarr.asmussen.tech"
            "prowlarr.asmussen.tech"
            "dsh.asmussen.tech"
            "worldmonitor.asmussen.tech"
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

      newsSync.push = {
        enable = true;
        llmModel = "hf.co/unsloth/Qwen3.5-9B-GGUF:Q6_K";
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

        # Keep the vault restorable with only age, tar and zstd.
        sources = [
          "dotfiles"
          "nix-secrets"
          ".password-store"
        ];

        # Use Restic for bulky data to avoid filling the 466G disk.
        incremental = {
          enable = true;
          passwordFile = config.sops.secrets."services/restic/vault-password".path;

          paths = [
            "Documents"
            "Pictures"
            "Videos"
            "Projects"
          ];
        };

        recipients = map (f: lib.strings.trim (builtins.readFile f)) lib.custom.keys.default.agePaths;
      };

      # Manage the router declaratively; apply changes with `just
      # router-restore`.
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

        # Retain disabled port forwards for declarative round-trips.
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
        worldmonitor.enable = mkForce false;
        deepseek-harness.enable = mkForce false;

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
