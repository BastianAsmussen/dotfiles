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

      rateType = types.submodule {
        options = {
          value = mkOption {
            type = types.int;
            description = "Numeric rate value.";
          };

          unit = mkOption {
            type = types.enum [
              "KiB/s"
              "MiB/s"
              "GiB/s"
            ];
            description = "Binary rate unit.";
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
            type = types.enum [
              "seconds"
              "minutes"
              "hours"
            ];
            description = "Duration unit.";
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
      '';
    in
    {
      options.qbittorrent = {
        webuiAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address the qBittorrent WebUI binds to.";
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
              [
                "services/qbittorrent/webui/password-hash"
                "services/qbittorrent/proxy/address"
                "services/qbittorrent/proxy/username"
                "services/qbittorrent/proxy/password"
              ]
              (_: {
                owner = svc.user;
              });

          templates."qbittorrent.conf" = {
            owner = svc.user;

            content = ''
              [BitTorrent]
              Session\AnonymousModeEnabled=true
              Session\DefaultSavePath=${completePath}/
              Session\Encryption=1
              Session\GlobalUPSpeedLimit=10240
              Session\MaxConnections=-1
              Session\MaxConnectionsPerTorrent=-1
              Session\Preallocation=${boolToString cfg.preallocate}
              Session\ProxyPeerConnections=true
              Session\QueueingSystemEnabled=${boolToString cfg.queueing.enable}
              Session\TempPath=${incompletePath}/
              Session\TempPathEnabled=true
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

              [Network]
              Proxy\AuthEnabled=true
              Proxy\HostnameLookupEnabled=false
              Proxy\IP=${config.sops.placeholder."services/qbittorrent/proxy/address"}
              Proxy\Password=${config.sops.placeholder."services/qbittorrent/proxy/password"}
              Proxy\Port=1080
              Proxy\Profiles\BitTorrent=true
              Proxy\Profiles\Misc=true
              Proxy\Profiles\RSS=true
              Proxy\Type=SOCKS5
              Proxy\Username=${config.sops.placeholder."services/qbittorrent/proxy/username"}

              [Preferences]
              Downloads\PreAllocation=${boolToString cfg.preallocate}
              Downloads\SavePath=${completePath}/
              Downloads\TempPath=${incompletePath}/
              Downloads\TempPathEnabled=true
              General\Locale=en
              General\StatusbarExternalIPDisplayed=true
              Queueing\QueueingEnabled=${boolToString cfg.queueing.enable}
              WebUI\Address=${cfg.webuiAddress}
              WebUI\Username=admin
              WebUI\Password_PBKDF2=${config.sops.placeholder."services/qbittorrent/webui/password-hash"}
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
            ++ optionals (torrentExportPath != null) [
              torrentExportPath
            ]
            ++ optionals (finishedTorrentExportPath != null) [
              finishedTorrentExportPath
            ];

            after = [
              "sops-install-secrets.service"
            ];

            serviceConfig.ExecStartPre = [
              "+${prepareScript}"
            ];
          };

          tmpfiles.rules = [
            "d ${torrentsPath}              2770 ${svc.user} media       - -"
            "d ${incompletePath}            2770 ${svc.user} media       - -"
            "d ${completePath}              2770 ${svc.user} media       - -"
            "d ${torrentFilesPath}          0700 ${svc.user} ${svc.user} - -"
          ]
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
