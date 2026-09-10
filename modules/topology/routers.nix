# The gateways on either end, and the internet between them. Not NixOS hosts,
# so they cannot declare themselves the way epsilon, delta and eta do.
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
