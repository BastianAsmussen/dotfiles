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

        # Acquisition-only roots for anime, kept out of the Jellyfin media tree:
        # Shoko is the librarian for anime, so these hold nothing Jellyfin
        # reads. Sonarr/Radarr hardlink-import here purely to track what they
        # already have.
        systemd.tmpfiles.rules = [
          "d /srv/media/sonarr        2775 root                           media - -"
          "d /srv/media/sonarr/anime  2770 ${config.services.sonarr.user} media - -"
          "d /srv/media/radarr        2775 root                           media - -"
          "d /srv/media/radarr/anime  2770 ${config.services.radarr.user} media - -"
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
