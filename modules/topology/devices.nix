# Non-NixOS devices on the network. Each owns its icon, since nothing else
# declares them.
{
  perSystem =
    { pkgs, ... }:
    {
      topology.modules = [
        (
          { config, ... }:
          {
            icons.devices.android.file = pkgs.runCommand "android.svg" { } ''
              sed 's|<title>[^<]*</title>||; s|<path |<path fill="#3DDC84" |' ${
                builtins.fetchurl {
                  url = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/android.svg";
                  sha256 = "0jrcq3bhl882ni367srnkm05akrl2426gm3nf7fhfgqn45g1qmzz";
                }
              } > $out
            '';

            nodes.muPhone = {
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
          }
        )
      ];
    };
}
