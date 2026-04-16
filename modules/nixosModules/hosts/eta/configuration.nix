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
      self.nixosModules.bootloader
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

    networking.hostName = "eta";
    topology.self = let
      inherit (config.lib.topology) mkConnection;
    in {
      hardware.info = "Hetzner Server";
      interfaces = {
        lan = {
          network = "cloud";
          type = "ethernet";
          addresses = [inputs.nix-secrets.hosts.eta.ipv4_address];
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
      ips = ["10.10.0.1/24"];
      listenPort = 51820;
      peers = [
        {
          publicKey = inputs.nix-secrets.hosts.epsilon.wg-public-key;
          allowedIPs = ["10.10.0.2/32"];
        }
        {
          publicKey = inputs.nix-secrets.hosts.delta.wg-public-key;
          allowedIPs = ["10.10.0.3/32"];
        }
      ];
    };

    # Eta is not fit for building, offload everything to Epsilon.
    # If Epsilon is unreachable, builds fail rather than running locally.
    nix.settings.max-jobs = lib.mkForce 0;

    btrfs.scrub.fileSystems = ["/"];
    nginx.reverseProxies.jellyfin = {
      enable = true;
      domain = "asmussen.tech";
      location = "/jellyfin";
      upstream = "http://10.10.0.2:8096";
      ssl = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
    };

    primaryMirror = {
      enable = true;
      services = {
        nix-cache = {
          primaryPort = config.services.nix-serve.port;
          localFallback = "localhost:${toString config.services.nix-serve.port}";
        };

        website = {
          primaryPort = config.services.website.port;
          localFallback = "localhost:${toString config.services.website.port}";
        };

        jellyfin = {
          nginxProxy = "jellyfin";
          primaryPort = 8096;
        };
      };
    };

    # Remote deployment.
    services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

    users.users.root.openssh.authorizedKeys.keyFiles = let
      keys = lib.custom.keys.default;
      wanted = ["ssh-epsilon.pub" "ssh-delta.pub"];
    in
      map (k: k.fullPath) (lib.filter (k: builtins.elem k.name wanted) keys.sshKeys);

    environment.systemPackages = [
      pkgs.neovim-minimal
    ];

    home-manager.userModules.bastian = with self.homeModules; [
      # Terminal
      git
      gpg
      zsh
      zoxide
      tmux
      ohMyPosh
      bat
      btop
      direnv
      eza
      fastfetch
      fzf
      ripgrep

      # Other
      sops
      qemu
    ];
  };
}
