{
  flake.nixosModules.servarr =
    { config, lib, ... }:
    {
      options.servarr.enable = lib.mkEnableOption "Enable the *arr stack.";

      config = lib.mkIf config.servarr.enable {
        users.extraGroups.media.members = [
          config.services.sonarr.user
          config.services.radarr.user
        ];

        systemd.services =
          let
            serviceConfig = {
              unitConfig.RequiresMountsFor = [ "/srv/media" ];
              serviceConfig.UMask = lib.mkForce "0002";
            };
          in
          {
            sonarr = serviceConfig;
            radarr = serviceConfig;
            prowlarr = serviceConfig;
          };

        services =
          let
            mkServarrConfig = port: {
              enable = true;
              openFirewall = false;
              settings = {
                update = {
                  automatically = false;
                  mechanism = "external";
                };

                server = {
                  inherit port;

                  bindaddress = "localhost";
                };

                log.analyticsEnabled = false;
              };
            };
          in
          {
            sonarr = mkServarrConfig 8989;
            radarr = mkServarrConfig 7878;
            prowlarr = mkServarrConfig 9696;

            flaresolverr = {
              enable = true;
              openFirewall = false;
            };
          };
      };
    };
}
