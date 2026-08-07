{
  inputs,
  ...
}:
{
  flake.nixosModules.news =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe
        getExe'
        mkEnableOption
        mkIf
        mkMerge
        mkOption
        types
        ;

      cfg = config.newsSync;

      # The receiver mirrors the daemon's dataDir layout for the website.
      inherit (cfg) remoteDir;

      pushScript = pkgs.writeShellScript "news-sync-push" ''
        set -euo pipefail

        key="${config.sops.secrets.${cfg.push.sshKeySecret}.path}"
        src="${config.services.news.dataDir}"

        for f in news.json digest.html; do
          if [ -f "$src/$f" ]; then
            ${getExe pkgs.openssh} \
              -o StrictHostKeyChecking=accept-new \
              -o ConnectTimeout=5 \
              -o BatchMode=yes \
              -i "$key" \
              "${cfg.push.sshUser}@${cfg.push.mirrorHost}" \
              "$f" < "$src/$f"
          fi
        done
      '';

      # The forced command accepts only feed files; `remoteDir` is
      # receive-user-owned.
      receiveScript = pkgs.writeShellScript "news-sync-receive" ''
        set -euo pipefail

        case "''${SSH_ORIGINAL_COMMAND:-}" in
          news.json|digest.html)
            dst="${remoteDir}/''${SSH_ORIGINAL_COMMAND}"
            tmp="$dst.tmp"
            trap '${getExe' pkgs.coreutils "rm"} -f "$tmp"' EXIT

            # Rename each uploaded feed into place so readers never see partial
            # files.
            ${getExe' pkgs.coreutils "install"} -m 0644 /dev/stdin "$tmp"
            ${getExe' pkgs.coreutils "mv"} -f "$tmp" "$dst"
            ;;
          *)
            echo "error: unsupported news-sync command" >&2
            exit 1
            ;;
        esac
      '';

      # A root .path unit watches the user's pause marker without polling.
      newsBusyToggle = pkgs.writeShellScript "news-busy-toggle" ''
        set -euo pipefail

        if [ -e /run/news/pause ]; then
          ${config.systemd.package}/bin/systemctl stop news.service
        else
          ${config.systemd.package}/bin/systemctl start news.service
        fi
      '';

      # A calendar timer schedules refreshes instead of tying them to boot time.
      newsRefresh = pkgs.writeShellScript "news-refresh" ''
        set -euo pipefail

        # Never wake the daemon mid-gamemode: the pause marker owns that.
        if [ -e /run/news/pause ]; then
          exit 0
        fi

        ${config.systemd.package}/bin/systemctl restart news.service
      '';
    in
    {
      options.newsSync = {
        remoteDir = mkOption {
          type = types.str;
          default = "/var/lib/news";
          description = ''
            Feed directory. On the pusher this must match the daemon's dataDir;
            on the receiver it is where the synced files land. The website
            reads "<remoteDir>/news.json".
          '';
        };

        push = {
          enable = mkEnableOption "running the news daemon and pushing its feed to the mirror host";

          mirrorHost = mkOption {
            type = types.str;
            default = "10.10.0.1";
            description = "WireGuard IP of the host receiving the feed.";
          };

          sshUser = mkOption {
            type = types.str;
            default = "news-sync";
            description = "Remote SSH user used to push feed files.";
          };

          sshKeySecret = mkOption {
            type = types.str;
            default = "hosts/epsilon/news-sync-ssh-private-key";
            description = "SOPS secret containing the SSH private key used to push the feed.";
          };

          interval = mkOption {
            type = types.ints.positive;
            default = 300;
            description = "Seconds between feed pushes.";
          };

          refreshTime = mkOption {
            type = types.str;
            default = "04:00";
            description = ''
              systemd OnCalendar expression for the daily aggregation pass. The
              pass saturates the GPU for as long as it runs, so this wants an
              hour the machine is otherwise idle.
            '';
          };
        };

        receive = {
          enable = mkEnableOption "receiving the synced news feed and exposing it to the website";

          sourceHost = mkOption {
            type = types.str;
            default = "10.10.0.2";
            description = "WireGuard IP of the host allowed to push the feed.";
          };

          sshGroup = mkOption {
            type = types.str;
            default = "news-sync";
            description = "System group owning the receive directory.";
          };

          authorizedKeys = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "SSH public keys allowed to push the feed (from the primary host).";
          };
        };
      };

      imports = [ inputs.news.nixosModules.default ];

      config = mkMerge [
        (mkIf cfg.push.enable {
          services.news = {
            enable = true;

            # Daily refreshes avoid keeping the GPU busy with model assessment.
            refreshIntervalSecs = 86400;
          };

          services.website.newsFile = "${config.services.news.dataDir}/news.json";

          programs.ssh.knownHosts."eta-wg-news" = {
            hostNames = [ cfg.push.mirrorHost ];
            publicKey = inputs.nix-secrets.hosts.eta.ssh-public-key;
          };

          sops.secrets.${cfg.push.sshKeySecret} = {
            mode = "0400";
          };

          systemd = {
            tmpfiles.rules = [
              "d /run/news 0755 ${config.preferences.user.name} ${config.preferences.user.name} - -"

              # A dynamic uid drifts; re-own files a previous uid left behind.
              "Z ${config.services.news.dataDir} - ${config.services.news.user} ${config.services.news.group} - -"
            ];

            services.news-refresh = {
              description = "Kick off the daily news aggregation pass";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = newsRefresh;
              };
            };

            timers.news-refresh = {
              description = "Daily news aggregation pass";
              wantedBy = [ "timers.target" ];

              timerConfig = {
                OnCalendar = cfg.push.refreshTime;
                # Catch up after downtime and jitter boot-time runs away from
                # login.
                Persistent = true;
                RandomizedDelaySec = "5min";
              };
            };

            services = {
              news-busy = {
                description = "Gate news daemon on gamemode state";
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = newsBusyToggle;
                };
              };

              news-sync = {
                description = "Push news feed to mirror host";
                after = [
                  "network-online.target"
                  "wireguard-wg0.service"
                  "news.service"
                ];

                wants = [ "network-online.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  ExecStart = pushScript;
                };
              };
            };

            paths.news-busy = {
              description = "React to gamemode pause marker changes";
              wantedBy = [ "multi-user.target" ];
              pathConfig.PathChanged = "/run/news/pause";
            };

            timers.news-sync = {
              description = "Periodic news feed push to mirror host";
              wantedBy = [ "timers.target" ];

              timerConfig = {
                OnBootSec = "2min";
                OnUnitActiveSec = "${toString cfg.push.interval}s";
              };
            };
          };
        })

        (mkIf cfg.receive.enable {
          users = {
            groups.${cfg.receive.sshGroup} = { };

            users.news-sync = {
              description = "News feed receiver";
              isSystemUser = true;
              createHome = false;
              group = cfg.receive.sshGroup;
              useDefaultShell = true;
              hashedPassword = "*";

              openssh.authorizedKeys.keys = map (
                key: ''restrict,from="${cfg.receive.sourceHost}",command="${receiveScript}" ${key}''
              ) cfg.receive.authorizedKeys;
            };
          };

          # Match preservation's rule exactly; duplicate tmpfiles lines must
          # agree.
          systemd.tmpfiles.rules = [
            "d ${remoteDir} 0755 news-sync ${cfg.receive.sshGroup} -"
          ];

          services.website.newsFile = "${remoteDir}/news.json";

          # Persist the latest feed and its receive-user ownership across
          # reboots.
          persistence.directories = [
            {
              directory = remoteDir;
              user = "news-sync";
              group = cfg.receive.sshGroup;
              mode = "0755";
            }
          ];
        })
      ];
    };
}
