{
  flake.nixosModules.base =
    { lib, ... }:
    {
      options.preferences.noctalia = {
        useIpLocation = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Use IP-based geolocation for weather instead of the static city name.";
        };

        idleEnabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable idle screen-off and lock timeouts.";
        };
      };
    };
}
