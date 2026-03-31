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
      renderer.hidePhysicalConnections = true;
    };
  };

  perSystem = {
    topology.modules = [
      ({config, ...}: let
        inherit (config.lib.topology) mkInternet mkRouter mkConnection;
      in {
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
          internet = mkInternet {
            connections = mkConnection "router" "wan";
          };

          router = mkRouter "Router" {
            info = "Home Router";
            interfaceGroups = [
              ["eth1" "wifi"]
              ["wan"]
            ];

            connections = {
              eth1 = mkConnection "lambda" "lan";
              wifi = mkConnection "delta" "wifi";
            };

            interfaces = {
              eth1.network = "home";
              wifi.network = "home";
            };
          };

          # Tailscale Mesh.
          delta.interfaces.tailscale0.physicalConnections = [
            (mkConnection "lambda" "tailscale0")
          ];
        };
      })
    ];
  };
}
