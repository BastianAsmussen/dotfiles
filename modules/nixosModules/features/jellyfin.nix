{
  flake.nixosModules.jellyfin =
    {
      lib,
      config,
      pkgs,
      options,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        ;

      cfg = config.jellyfin;
      svc = config.services.jellyfin;

      user = config.preferences.user.name;
      jellyfinUser = svc.user;
      jellyfinGroup = svc.group;
    in
    {
      options.jellyfin = {
        enable = lib.mkEnableOption "the Jellyfin media stack";

        uid = mkOption {
          type = lib.types.ints.positive;
          default = 996;
        };

        gid = mkOption {
          type = types.ints.positive;
          default = 995;
        };

        mediaGid = mkOption {
          type = types.ints.positive;
          default = 994;
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            users = {
              users.${jellyfinUser}.uid = cfg.uid;

              groups = {
                ${jellyfinGroup}.gid = cfg.gid;

                media = {
                  gid = cfg.mediaGid;
                  members = [
                    user
                    jellyfinUser
                    "shoko"
                  ];
                };
              };
            };

            systemd = {
              tmpfiles.rules = [
                "d /srv/media                  0755 root            media - -"
                "d /srv/media/jellyfin         2770 ${jellyfinUser} media - -"
                "d /srv/media/jellyfin/Shows   2770 ${jellyfinUser} media - -"
                "d /srv/media/jellyfin/Movies  2770 ${jellyfinUser} media - -"
              ];

              services = {
                jellyfin = {
                  unitConfig.RequiresMountsFor = [ "/srv/media" ];
                  serviceConfig.UMask = lib.mkForce "0002";
                  environment.LC_ALL = config.i18n.defaultLocale;
                };

                shoko.unitConfig.RequiresMountsFor = [ "/srv/media" ];
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

            environment.systemPackages = with pkgs; [
              jellyfin
              jellyfin-web
              jellyfin-ffmpeg
              shoko
            ];
          }

          (lib.optionalAttrs (options ? persistence) {
            persistence = {
              directories = [
                {
                  directory = svc.dataDir;
                  user = jellyfinUser;
                  group = jellyfinGroup;
                }
              ];

              directoriesWithMode.${svc.cacheDir} = "0755";
            };
          })
        ]
      );
    };
}
