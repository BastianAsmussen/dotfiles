# Declare gateways and internet links that cannot self-declare as NixOS hosts.
{
  perSystem = {
    topology.modules = [
      (
        { config, ... }:
        {
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
