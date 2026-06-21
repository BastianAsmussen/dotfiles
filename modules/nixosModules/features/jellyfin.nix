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
      cfg = config.services.jellyfin;
      jellyfinUser = config.services.jellyfin.user;
      jellyfinGroup = config.services.jellyfin.group;
    in
    {
      users = lib.mkIf cfg.enable {
        # Pin IDs so they stay stable across rebuilds. The /srv/media payloads
        # and Jellyfin state are owned by these numeric IDs; an unpinned
        # service can drift on rebuild and orphan every file it owns.
        users.${jellyfinUser}.uid = 996;

        groups = {
          ${jellyfinGroup}.gid = 995;
          media.gid = 994;
        };

        extraGroups.media.members = [
          user
          jellyfinUser
          "shoko"
        ];
      };

      systemd = lib.mkIf cfg.enable {
        tmpfiles.rules = [
          "d /srv/media                 0755 root            media - -"
          "d /srv/media/jellyfin        2770 ${jellyfinUser} media - -"
          "d /srv/media/jellyfin/Shows  2770 ${jellyfinUser} media - -"
          "d /srv/media/jellyfin/Movies 2770 ${jellyfinUser} media - -"
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

        meilisearch.enable = true;

        shoko.enable = true;
      };

      environment.systemPackages = lib.mkIf cfg.enable (
        with pkgs;
        [
          jellyfin
          jellyfin-web
          jellyfin-ffmpeg
          shoko
        ]
      );
    };
}
