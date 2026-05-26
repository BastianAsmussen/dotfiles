{
  flake.nixosModules.seerr =
    { config, lib, ... }:
    {
      options.seerr.enable = lib.mkEnableOption "Seerr request management.";

      config = lib.mkIf config.seerr.enable {
        services.seerr = {
          enable = true;
          openFirewall = false;
        };
      };
    };
}
