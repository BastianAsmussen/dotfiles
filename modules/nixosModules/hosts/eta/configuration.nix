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

  flake.nixosModules.hostEta = {config, ...}: {
    imports = [
      # Base modules
      self.nixosModules.base
      self.nixosModules.bootloader
      self.nixosModules.language

      # Nix
      self.nixosModules.nix
      self.nixosModules.nh

      # Security
      self.nixosModules.security
      self.nixosModules.sops
      self.nixosModules.ssh
      self.nixosModules.tailscale

      # Features
      self.nixosModules.btrfs
      self.nixosModules.networkManager
      self.nixosModules.nginx
      self.nixosModules.nix-serve
      self.nixosModules.topology

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
          addresses = ["49.13.7.174"];
          physicalConnections = [
            (mkConnection "cloudRouter" "eth1")
          ];
        };

        tailscale0.physicalConnections = [
          (mkConnection "lambda" "tailscale0")
        ];
      };
    };

    btrfs.scrub.fileSystems = ["/"];
  };
}
