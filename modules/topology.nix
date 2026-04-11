{inputs, ...}: {
  imports = [inputs.nix-topology.flakeModule];

  flake.nixosModules.topology = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.nix-topology.nixosModules.default];

    topology.self.interfaces.tailscale0 = lib.mkIf config.services.tailscale.enable {
      type = "wireguard";
      network = "tailscale";
    };
  };

  perSystem = {
    topology.modules = [
      ({config, ...}: {
        networks = {
          home = {
            name = "Home Network";
            cidrv4 = "192.168.1.0/24";
          };

          tailscale = {
            name = "Tailscale VPN";
            cidrv4 = "100.64.0.0/10";
          };
        };

        nodes = {
          internet = config.lib.topology.mkInternet {
            connections = config.lib.topology.mkConnection "router" "wan";
          };

          router = config.lib.topology.mkRouter "Router" {
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
