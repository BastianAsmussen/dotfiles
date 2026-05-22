{
  flake.nixosModules.qbittorrent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        boolToString
        concatStringsSep
        escapeShellArg
        mapAttrsToList
        mkIf
        mkEnableOption
        mkOption
        optionalString
        optionals
        removeSuffix
        types
        ;

      inherit (lib.custom.units) durationToSeconds rateToKiBps;

      cfg = config.qbittorrent;
      svc = config.services.qbittorrent;

      install = lib.getExe' pkgs.coreutils "install";
      mktemp = lib.getExe' pkgs.coreutils "mktemp";
      rm = lib.getExe' pkgs.coreutils "rm";
      sleep = lib.getExe' pkgs.coreutils "sleep";
      curl = lib.getExe pkgs.curl;

      torrentsPath = removeSuffix "/" cfg.torrentsPath;
      incompletePath = removeSuffix "/" cfg.incompletePath;
      completePath = removeSuffix "/" cfg.completePath;
      torrentFilesPath = removeSuffix "/" cfg.torrentFiles.path;

      torrentExportPath =
        if cfg.torrentFiles.exportPath == null then null else removeSuffix "/" cfg.torrentFiles.exportPath;

      finishedTorrentExportPath =
        if cfg.torrentFiles.finishedExportPath == null then
          null
        else
          removeSuffix "/" cfg.torrentFiles.finishedExportPath;

      categories = mapAttrsToList (name: category: {
        inherit name;
        path = removeSuffix "/" (
          if category.path == null then "${completePath}/${name}" else category.path
        );
      }) cfg.categories;

      categoryPaths = map (category: category.path) categories;
      categoryTmpfilesRules = map (category: "d ${category.path} 2770 ${svc.user} media - -") categories;
      categoryInstallCommands = concatStringsSep "\n" (
        map (category: ''
          ${install} -d \
            -m 2770 \
            -o ${svc.user} \
            -g media \
            ${escapeShellArg category.path}
        '') categories
      );

      categorySyncCommands = concatStringsSep "\n" (
        map (category: ''
          ensure_category ${escapeShellArg category.name} ${escapeShellArg category.path}
        '') categories
      );

      rateType = types.submodule {
        options = {
          value = mkOption {
            type = types.int;
            description = "Numeric rate value.";
          };

          unit = mkOption {
            description = "Binary rate unit.";
            type = types.enum [
              "KiB/s"
              "MiB/s"
              "GiB/s"
            ];
          };
        };
      };

      durationType = types.submodule {
        options = {
          value = mkOption {
            type = types.int;
            description = "Numeric duration value.";
          };

          unit = mkOption {
            description = "Duration unit.";
            type = types.enum [
              "seconds"
              "minutes"
              "hours"
            ];
          };
        };
      };

      prepareScript = pkgs.writeShellScript "qbittorrent-prepare" ''
        set -euo pipefail

        ${install} -d \
          -m 2770 \
          -o ${svc.user} \
          -g media \
          "${torrentsPath}" \
          "${incompletePath}" \
          "${completePath}"

        ${install} -d \
          -m 0700 \
          -o ${svc.user} \
          "${svc.profileDir}/qBittorrent/config" \
          "${torrentFilesPath}"

        ${optionalString (torrentExportPath != null) ''
          ${install} -d \
            -m 0700 \
            -o ${svc.user} \
            "${torrentExportPath}"
        ''}

        ${optionalString (finishedTorrentExportPath != null) ''
          ${install} -d \
            -m 0700 \
            -o ${svc.user} \
            "${finishedTorrentExportPath}"
        ''}

        ${install} \
          -m 0600 \
          -o ${svc.user} \
          "${config.sops.templates."qbittorrent.conf".path}" \
          "${svc.profileDir}/qBittorrent/config/qBittorrent.conf"

        ${categoryInstallCommands}
      '';

      syncCategoriesScript = pkgs.writeShellScript "qbittorrent-sync-categories" ''
        set -euo pipefail

        base_url="http://${cfg.webuiAddress}:${toString svc.webuiPort}"
        cookie_jar="$(${mktemp} -t qbittorrent-cookies.XXXXXX)"
        trap '${rm} -f "$cookie_jar"' EXIT

        login() {
          ${curl} -sS -o /dev/null -w "%{http_code}" \
            -c "$cookie_jar" \
            -H "Referer: $base_url" \
            --data-urlencode ${escapeShellArg "username=${cfg.webuiUsername}"} \
            --data-urlencode ${escapeShellArg "password@${cfg.webuiPasswordFile}"} \
            "$base_url/api/v2/auth/login"
        }

        for attempt in {1..60}; do
          status="$(login 2>/dev/null || true)"

          case "$status" in
            200|204) break;;
          esac

          if [ "$attempt" -eq 60 ]; then
            echo "qBittorrent WebUI authentication did not succeed at $base_url (last HTTP $status)!" >&2
            exit 1
          fi

          ${sleep} 1
        done

        post_status() {
          local endpoint="$1"
          shift

          ${curl} -sS -o /dev/null -w "%{http_code}" -X POST \
            -b "$cookie_jar" \
            -H "Referer: $base_url" \
            "$@" \
            "$base_url$endpoint"
        }

        ensure_category() {
          local category="$1"
          local save_path="$2"
          local status

          status="$(post_status "/api/v2/torrents/createCategory" \
            --data-urlencode "category=$category" \
            --data-urlencode "savePath=$save_path")"

          case "$status" in
            200) echo "Created qBittorrent category: $category";;
            409) echo "qBittorrent category already exists: $category";;
            *) echo "Failed to create qBittorrent category '$category' (HTTP $status)" >&2; exit 1;;
          esac

          status="$(post_status "/api/v2/torrents/editCategory" \
            --data-urlencode "category=$category" \
            --data-urlencode "savePath=$save_path")"

          case "$status" in
            200) echo "Reconciled qBittorrent category: $category -> $save_path";;
            409) echo "qBittorrent category '$category' already set to '$save_path'.";;
            *) echo "Failed to edit qBittorrent category '$category' (HTTP $status)" >&2; exit 1;;
          esac
        }

        ${categorySyncCommands}
      '';
    in
    {
      options.qbittorrent = {
        webuiAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address the qBittorrent WebUI binds to.";
        };

        webuiUsername = mkOption {
          type = types.str;
          default = "admin";
          description = "Username used by the category sync service to authenticate to the qBittorrent WebUI API.";
        };

        webuiPasswordFile = mkOption {
          type = types.str;
          default = config.sops.secrets."services/qbittorrent/webui/password".path;
          description = ''
            Path to a root-readable/qbittorrent-readable file containing the
            plaintext qBittorrent WebUI password used for authenticated WebUI
            API calls. This is separate from the PBKDF2 hash qBittorrent stores
            in qBittorrent.conf.
          '';
        };

        torrentsPath = mkOption {
          type = types.str;
          default = "/srv/media/torrents";
          description = "Root directory for qBittorrent-managed torrent payloads.";
        };

        incompletePath = mkOption {
          type = types.str;
          default = "${removeSuffix "/" svc.profileDir}/qBittorrent/data/incomplete";
          description = "Path where qBittorrent stores incomplete downloads.";
        };

        completePath = mkOption {
          type = types.str;
          default = "${removeSuffix "/" cfg.torrentsPath}/complete";
          description = "Path where qBittorrent stores completed downloads.";
        };

        autoTorrentManagement = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether new torrents default to automatic torrent management (ATM)
            mode. When enabled, qBittorrent automatically sets the save path
            based on the selected category, including in the Add Torrent dialog.
          '';
        };

        useCategoryPathsInManualMode = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether qBittorrent should use category save paths as the base path
            when torrents are using manual torrent management.
          '';
        };

        categories = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                path = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Absolute save path for this qBittorrent category.

                    If null, defaults to ''${cfg.completePath}/''${name}.
                  '';
                };
              };
            }
          );

          default = { };

          example = {
            anime = { };
            movies.path = "/srv/media/torrents/complete/movies";
          };

          description = ''
            qBittorrent categories to create and keep reconciled via the WebUI
            API. Category directories are created with tmpfiles using the media
            group and setgid permissions.
          '';
        };

        networkInterface = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Network interface to bind all BitTorrent traffic to (e.g. "pia0").
            Sets Session\NetworkInterface in qBittorrent.conf so libtorrent binds
            both its listen socket and outgoing connections to this interface,
            ensuring the correct source IP is used.
          '';
        };

        preallocate = mkOption {
          type = types.bool;
          default = true;
          description = "Whether qBittorrent preallocates disk space for torrent payloads.";
        };

        queueing = {
          enable = mkEnableOption "qBittorrent torrent queueing";

          maxActiveDownloads = mkOption {
            type = types.int;
            default = 2;
            description = "Maximum number of active qBittorrent downloads.";
          };

          maxActiveUploads = mkOption {
            type = types.int;
            default = -1;
            description = "Maximum number of active qBittorrent uploads.";
          };

          maxActiveTorrents = mkOption {
            type = types.int;
            default = -1;
            description = "Maximum number of active qBittorrent torrents.";
          };

          ignoreSlowTorrents = mkOption {
            type = types.bool;
            default = true;
            description = "Whether slow torrents should be ignored for queueing limits.";
          };

          slow = {
            downloadRate = mkOption {
              type = rateType;
              default = {
                value = 5;
                unit = "KiB/s";
              };
              apply = rateToKiBps;
              description = "Download rate below which a torrent is considered slow.";
            };

            uploadRate = mkOption {
              type = rateType;
              default = {
                value = 1;
                unit = "GiB/s";
              };
              apply = rateToKiBps;
              description = ''
                Upload rate below which a torrent is considered slow.

                Intentionally high so upload activity does not keep a
                non-progressing incomplete torrent counted against the active
                download limit.
              '';
            };

            inactiveTimer = mkOption {
              type = durationType;
              default = {
                value = 60;
                unit = "seconds";
              };

              apply = durationToSeconds;
              description = "Duration before a low-activity torrent is considered slow.";
            };
          };
        };

        torrentFiles = {
          path = mkOption {
            type = types.str;
            default = "${removeSuffix "/" svc.profileDir}/qBittorrent/data/torrents";
            description = "Root directory for exported .torrent metadata files.";
          };

          exportPath = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Directory where qBittorrent copies .torrent files.

              Null disables exporting all added .torrent files.
            '';
          };

          finishedExportPath = mkOption {
            type = types.nullOr types.str;
            default = "${removeSuffix "/" svc.profileDir}/qBittorrent/data/torrents/finished";
            description = ''
              Directory where qBittorrent copies .torrent files for completed
              downloads.

              Null disables exporting completed .torrent files.
            '';
          };
        };
      };

      config = {
        sops = {
          secrets =
            lib.genAttrs
              (
                [
                  "services/qbittorrent/webui/password-hash"
                ]
                ++ optionals (categories != [ ]) [
                  "services/qbittorrent/webui/password"
                ]
              )
              (_: {
                owner = svc.user;
              });

          templates."qbittorrent.conf" = {
            owner = svc.user;

            content = ''
              [BitTorrent]
              Session\DefaultSavePath=${completePath}/
              Session\AnonymousModeEnabled=true
              Session\Encryption=0
              Session\GlobalUPSpeedLimit=10240
              Session\MaxConnections=-1
              Session\MaxConnectionsPerTorrent=-1
              Session\Preallocation=${boolToString cfg.preallocate}
              Session\QueueingSystemEnabled=${boolToString cfg.queueing.enable}
              Session\TempPath=${incompletePath}/
              Session\TempPathEnabled=true
              Session\DisableAutoTMMByDefault=${boolToString (!cfg.autoTorrentManagement)}
              Session\UseCategoryPathsInManualMode=${boolToString cfg.useCategoryPathsInManualMode}
              ${optionalString (cfg.networkInterface != null) ''
                Session\Interface=${cfg.networkInterface}
                Session\InterfaceName=${cfg.networkInterface}
              ''}
              ${optionalString cfg.queueing.enable ''
                Session\IgnoreSlowTorrentsForQueueing=${boolToString cfg.queueing.ignoreSlowTorrents}
                Session\MaxActiveDownloads=${toString cfg.queueing.maxActiveDownloads}
                Session\MaxActiveTorrents=${toString cfg.queueing.maxActiveTorrents}
                Session\MaxActiveUploads=${toString cfg.queueing.maxActiveUploads}
                Session\SlowTorrentsDownloadRate=${toString cfg.queueing.slow.downloadRate}
                Session\SlowTorrentsInactivityTimer=${toString cfg.queueing.slow.inactiveTimer}
                Session\SlowTorrentsUploadRate=${toString cfg.queueing.slow.uploadRate}
              ''}
              ${optionalString (torrentExportPath != null) ''
                Session\TorrentExportDirectory=${torrentExportPath}/
              ''}
              ${optionalString (finishedTorrentExportPath != null) ''
                Session\FinishedTorrentExportDirectory=${finishedTorrentExportPath}/
              ''}

              [LegalNotice]
              Accepted=true

              [Preferences]
              Connection\UPnP=false
              Connection\NATPMP=false
              Downloads\PreAllocation=${boolToString cfg.preallocate}
              Downloads\SavePath=${completePath}/
              Downloads\TempPath=${incompletePath}/
              Downloads\TempPathEnabled=true
              General\Locale=en
              General\StatusbarExternalIPDisplayed=true
              Queueing\QueueingEnabled=${boolToString cfg.queueing.enable}
              WebUI\Address=${cfg.webuiAddress}
              WebUI\Username=${cfg.webuiUsername}
              WebUI\Password_PBKDF2=${config.sops.placeholder."services/qbittorrent/webui/password-hash"}
              WebUI\LocalHostAuth=true
              ${optionalString cfg.queueing.enable ''
                Queueing\IgnoreSlowTorrents=${boolToString cfg.queueing.ignoreSlowTorrents}
                Queueing\MaxActiveDownloads=${toString cfg.queueing.maxActiveDownloads}
                Queueing\MaxActiveTorrents=${toString cfg.queueing.maxActiveTorrents}
                Queueing\MaxActiveUploads=${toString cfg.queueing.maxActiveUploads}
              ''}
              ${optionalString (torrentExportPath != null) ''
                Downloads\TorrentExportDir=${torrentExportPath}/
              ''}
              ${optionalString (finishedTorrentExportPath != null) ''
                Downloads\FinishedTorrentExportDir=${finishedTorrentExportPath}/
              ''}
            '';
          };
        };

        services.qbittorrent = {
          enable = true;
          webuiPort = 8081;
        };

        systemd = {
          services.qbittorrent = {
            unitConfig.RequiresMountsFor = [
              torrentsPath
              incompletePath
              completePath
              torrentFilesPath
            ]
            ++ categoryPaths
            ++ optionals (torrentExportPath != null) [
              torrentExportPath
            ]
            ++ optionals (finishedTorrentExportPath != null) [
              finishedTorrentExportPath
            ];

            after = [
              "sops-install-secrets.service"
            ];

            restartTriggers = [ config.sops.templates."qbittorrent.conf".content ];
            serviceConfig = {
              ExecStartPre = [ "+${prepareScript}" ];
              NoNewPrivileges = true;
              CapabilityBoundingSet = "";
              LockPersonality = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
            };
          };

          services.qbittorrent-sync-categories = mkIf (categories != [ ]) {
            description = "Create and reconcile qBittorrent categories";
            requires = [ "qbittorrent.service" ];
            after = [ "qbittorrent.service" ];
            wantedBy = [ "multi-user.target" ];
            restartTriggers = [ syncCategoriesScript ];

            unitConfig.RequiresMountsFor = categoryPaths;

            serviceConfig = {
              Type = "oneshot";
              User = svc.user;
              Group = "media";
              ExecStart = syncCategoriesScript;
            };
          };

          tmpfiles.rules = [
            "d ${torrentsPath}              2770 ${svc.user} media       - -"
            "d ${incompletePath}            2770 ${svc.user} media       - -"
            "d ${completePath}              2770 ${svc.user} media       - -"
            "d ${torrentFilesPath}          0700 ${svc.user} ${svc.user} - -"
          ]
          ++ categoryTmpfilesRules
          ++ optionals (torrentExportPath != null) [
            "d ${torrentExportPath}         0700 ${svc.user} ${svc.user} - -"
          ]
          ++ optionals (finishedTorrentExportPath != null) [
            "d ${finishedTorrentExportPath} 0700 ${svc.user} ${svc.user} - -"
          ];
        };

        users = {
          groups.media = { };

          extraGroups.media.members = [
            svc.user
          ];
        };
      };
    };
}
