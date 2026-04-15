{inputs, ...}: {
  imports = [inputs.nix-topology.flakeModule];

  flake.nixosModules.topology = {
    imports = [inputs.nix-topology.nixosModules.default];
  };

  perSystem = {
    topology.modules = [
      ({config, ...}: {
        networks = {
          home = {
            name = "Home Network";
            cidrv4 = "192.168.1.0/24";
          };

          cloud = {
            name = "Hetzner Network";
            cidrv4 = "${inputs.nix-secrets.hosts.eta.ipv4_address}/32";
            cidrv6 = "2a01:4f8:c014:4725::/64";
          };
        };

        nodes = {
          internet = config.lib.topology.mkInternet {
            connections = [
              (config.lib.topology.mkConnection "cloudRouter" "wan")
              (config.lib.topology.mkConnection "homeRouter" "wan")
            ];
          };

          cloudRouter = config.lib.topology.mkRouter "Hetzner" {
            info = "Cloud Router";
            interfaceGroups = [
              ["eth1"]
              ["wan"]
            ];

            interfaces.eth1.network = "cloud";
          };

          homeRouter = config.lib.topology.mkRouter "Home" {
            info = "Home Router";
            interfaceGroups = [
              ["eth1" "wifi"]
              ["wan"]
            ];

            interfaces = {
              eth1.network = "home";
              wifi.network = "home";
            };
          };
        };
      })
    ];
  };
}
