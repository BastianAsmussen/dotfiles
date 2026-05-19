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
        self.nixosModules.qbittorrent
        self.nixosModules.syncthing
        self.nixosModules.primaryBusy
        self.nixosModules.monero
        self.nixosModules.networkManager
        self.nixosModules.nginx
        self.nixosModules.nix-serve
        self.nixosModules.nvidia
        self.nixosModules.topology
        self.nixosModules.virtualisation
        self.nixosModules.website
        self.nixosModules.winapps
        self.nixosModules.arcticVault

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
        };

      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
      };

      sops.secrets."wireguard/psk-eta-epsilon" = { };

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
          "/var/lib/fail2ban"
          "/var/lib/power-profiles-daemon"
          {
            directory = "/var/lib/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
          }
          "/var/lib/qBittorrent"
          "/var/lib/systemd/coredump"
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
            ".config/teams-for-linux"
            ".mozilla"
            ".password-store"
            ".pki"
            ".ssh"

            ".local/share"

            ".local/state/home-manager"
            ".local/state/nix"
            ".local/state/nvim"
            ".local/state/wireplumber"
            ".local/state/mpv"
          ];

          directoriesWithMode.".gnupg" = "0700";

          cache.directories = [
            ".cache/direnv"
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

      nix-serve-extras.bindAddress = "10.10.0.2";
      nginx = {
        acme.sharedHost = "asmussen.tech";

        reverseProxies = {
          jellyfin = {
            enable = true;
            domain = "jellyfin.asmussen.tech";
            location = "/";
            upstream = "https://localhost:8920";
            proxySSL.verify = false;
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
              caCertificate = ../../../../keys/mtls-ca.crt;
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
              caCertificate = ../../../../keys/mtls-ca.crt;
              localhostBypass = true;
            };
          };
        };
      };

      services = {
        nginx.virtualHosts = {
          "www.asmussen.tech" = {
            useACMEHost = "asmussen.tech";
            forceSSL = true;
            locations."/".return = "301 https://asmussen.tech$request_uri";
          };

          # Redirect legacy path to subdomain for existing bookmarks.
          "asmussen.tech".locations."/jellyfin".return = "301 https://jellyfin.asmussen.tech/";
        };

        openssh.openFirewall = false;
      };

      qbittorrent.categories = {
        anime = { };
        shows = { };
        movies = { };
      };

      # Resolve qbittorrent to loopback so the browser hits the local mTLS proxy
      # instead of going out through eta (bypasses public DNS and the untrusted hop).
      networking = {
        hosts = {
          "127.0.0.1" = [
            "qbittorrent.asmussen.tech"
            "shoko.asmussen.tech"
          ];

          "::1" = [
            "qbittorrent.asmussen.tech"
            "shoko.asmussen.tech"
          ];
        };

        # Allow WireGuard peers (eta, delta) to reach proxied services on epsilon.
        firewall.interfaces.wg0.allowedTCPPorts = config.services.openssh.ports ++ [
          config.services.nix-serve.port
          config.services.website.port
          443 # nginx, WG peers reach epsilon directly
          8920 # Jellyfin HTTPS
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

      jellyfin.https = {
        enable = true;
        acmeHost = "asmussen.tech";
      };

      winapps.enable = true;

      japanese.enable = true;
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
    };
}
