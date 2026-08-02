{
  flake.nixosModules.youtubeArchive =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        ;

      cfg = config.youtubeArchive;

      instanceName = "youtube";
      serviceName = "ytdl-sub-${instanceName}";

      serviceUser = "ytdl-sub";
      serviceGroup = "media";
    in
    {
      options.youtubeArchive = {
        enable = lib.mkEnableOption "YouTube archiving for Jellyfin";

        uid = mkOption {
          type = types.ints.positive;
          example = 984;
          description = ''
            Stable UID assigned to the ytdl-sub system user.

            This must remain stable because ytdl-sub owns persistent files
            under the media library.
          '';
        };

        libraryPath = mkOption {
          type = types.path;
          default = "/srv/media/jellyfin/YouTube";
          description = ''
            Root directory exposed to Jellyfin as a Shows library.
          '';
        };

        workingDirectory = mkOption {
          type = types.path;
          default = "/srv/media/.ytdl-sub-working";
          description = ''
            Temporary download and processing directory.

            This should be on the same filesystem as libraryPath so completed
            files can be moved into the library without crossing filesystems.
          '';
        };

        schedule = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "daily";
          description = ''
            Optional systemd calendar expression.

            Null leaves the service manual-only.
          '';
        };

        channels = mkOption {
          type = types.attrsOf (types.either types.str (types.listOf types.str));

          default = { };

          example = lib.literalExpression ''
            {
              Veritasium = "https://www.youtube.com/@veritasium";

              "Rick Beato" = [
                "https://www.youtube.com/@RickBeato"
                "https://www.youtube.com/@rickbeato240"
              ];
            }
          '';

          description = ''
            YouTube channels or playlists to archive.

            Each attribute name becomes the show name in Jellyfin. A show may
            use either one URL or a list of URLs.
          '';
        };

        presets = mkOption {
          type = types.listOf types.str;

          default = [
            "Jellyfin TV Show by Date"
            "Max 1080p"
          ];

          description = "ytdl-sub presets applied to every configured show.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = config.jellyfin.enable;
            message = "youtubeArchive requires jellyfin.enable.";
          }
          {
            assertion = cfg.channels != { };
            message = "youtubeArchive.channels must contain at least one subscription.";
          }
          {
            assertion = cfg.presets != [ ];
            message = "youtubeArchive.presets must contain at least one preset.";
          }
          {
            assertion = cfg.libraryPath != cfg.workingDirectory;
            message = "youtubeArchive.libraryPath and workingDirectory must be different.";
          }
        ];

        # ytdl-sub owns files on persistent storage, so its numeric identity
        # must remain stable between rebuilds.
        users.users.${serviceUser}.uid = cfg.uid;

        services.ytdl-sub = {
          # Explicitly own these global settings rather than pinning whichever
          # user another module may have selected.
          user = serviceUser;
          group = serviceGroup;

          instances.${instanceName} = {
            enable = true;

            inherit (cfg) schedule;

            readWritePaths = [
              cfg.libraryPath
              cfg.workingDirectory
            ];

            config = {
              configuration = {
                # The upstream NixOS module sets this to /run/ytdl-sub/youtube.
                working_directory = lib.mkForce cfg.workingDirectory;

                # RuntimeDirectory creates this beneath /run.
                lock_directory = "/run/ytdl-sub/${instanceName}";

                # Keep generated files writable by members of media.
                umask = "002";
              };

              presets."YouTube TV Show" = {
                preset = cfg.presets;
                overrides.tv_show_directory = cfg.libraryPath;
              };
            };

            subscriptions."YouTube TV Show" = cfg.channels;
          };
        };

        systemd = {
          tmpfiles.rules = [
            "d ${cfg.libraryPath}      2770 ${serviceUser} ${serviceGroup} - -"
            "d ${cfg.workingDirectory} 2770 ${serviceUser} ${serviceGroup} - -"
          ];

          services.${serviceName} = {
            # These paths may be placed on separate mounts by the caller.
            unitConfig.RequiresMountsFor = [
              cfg.libraryPath
              cfg.workingDirectory
            ];

            environment = {
              TMPDIR = cfg.workingDirectory;
              LC_ALL = config.i18n.defaultLocale;
            };

            serviceConfig.UMask = lib.mkForce "0002";
          };
        };
      };
    };
}
