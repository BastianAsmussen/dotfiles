{
  flake.nixosModules.jellyfin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.preferences.user.name;
      jellyfinUser = config.services.jellyfin.user;
    in
    {
      users = {
        groups.media = { };
        extraGroups.media.members = [
          user
          jellyfinUser
          "shoko"
        ];
      };

      systemd = {
        tmpfiles.rules = [
          "d /srv/media          0755 root            media - -"
          "d /srv/media/shared   3770 root            media - -"
          "d /srv/media/jellyfin 2770 ${jellyfinUser} media - -"
        ];

        services = {
          jellyfin = {
            unitConfig.RequiresMountsFor = [
              "/srv/media"
            ];

            serviceConfig.UMask = lib.mkForce "0002";

            # Override service locale.
            environment.LC_ALL = config.i18n.defaultLocale;
          };

          shoko.unitConfig.RequiresMountsFor = [
            "/srv/media"
          ];
        };
      };

      services = {
        jellyfin = {
          enable = true;
          openFirewall = false;
        };

        shoko.enable = true;
      };

      environment.systemPackages = with pkgs; [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
        shoko
      ];
    };
}
