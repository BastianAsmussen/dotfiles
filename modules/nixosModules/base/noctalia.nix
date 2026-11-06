{
  flake.nixosModules.base =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.preferences.noctalia = {
        useIpLocation = mkOption {
          type = types.bool;
          default = false;
          description = "Use IP-based geolocation for weather instead of the static city name.";
        };

        idleEnabled = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable idle screen-off and lock timeouts.";
        };

        powerProfileEnabled = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to show power profile controls in the bar and control center.";
        };

        screenshotDirectory = mkOption {
          type = types.str;
          default = "~/Pictures/Screenshots/${config.networking.hostName}";
          defaultText = lib.literalExpression ''"~/Pictures/Screenshots/''${config.networking.hostName}"'';
          description = "Folder screenshots are saved to, kept per host so synced Pictures folders never collide.";
        };
      };
    };
}
