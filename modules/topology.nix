{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  flake.nixosModules.topology = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };

  perSystem =
    { pkgs, ... }:
    {
      topology.modules = [
        (
          { config, ... }:
          {
            icons = {
              services.syncthing.file = "${pkgs.syncthing}/share/icons/hicolor/scalable/apps/syncthing.svg";
              devices.android.file = pkgs.runCommand "android.svg" { } ''
                sed 's|<title>[^<]*</title>||; s|<path |<path fill="#3DDC84" |' ${
                  builtins.fetchurl {
                    url = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/android.svg";
                    sha256 = "0jrcq3bhl882ni367srnkm05akrl2426gm3nf7fhfgqn45g1qmzz";
                  }
                } > $out
              '';
            };

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
              muPhone = {
                deviceType = "device";
                name = "mu (Android)";
                hardware.info = "Android Phone";
                deviceIcon = "devices.android";
                interfaces = {
                  wifi.physicalConnections = [
                    (config.lib.topology.mkConnection "homeRouter" "wifi")
                  ];

                  wg0.physicalConnections = [
                    (config.lib.topology.mkConnection "eta" "wg0")
                  ];
                };

                services.syncthing = {
                  name = "Syncthing";
                  icon = "services.syncthing";
                };
              };

              internet = config.lib.topology.mkInternet {
                connections = [
                  (config.lib.topology.mkConnection "cloudRouter" "wan")
                  (config.lib.topology.mkConnection "homeRouter" "wan")
                ];
              };

              cloudRouter = config.lib.topology.mkRouter "Hetzner" {
                info = "Cloud Router";
                interfaceGroups = [
                  [ "eth1" ]
                  [ "wan" ]
                ];

                interfaces.eth1.network = "cloud";
              };

              homeRouter = config.lib.topology.mkRouter "Home" {
                info = "Home Router";
                interfaceGroups = [
                  [
                    "eth1"
                    "wifi"
                  ]
                  [ "wan" ]
                ];

                interfaces = {
                  eth1.network = "home";
                  wifi.network = "home";
                };
              };
            };
          }
        )
      ];
    };
}
