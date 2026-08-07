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

      # The daemon writes its output files (news.json, digest.html) into its
      # dataDir on the pusher; the receiver keeps the same layout so the
      # website always reads "<dir>/news.json".
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

      # Forced command on the receiver's authorized key: only these two file
      # names may be written, only from the primary host, and the payload is
      # read from stdin so no scp/rsync machinery is exposed.
      #
      # This runs as the unprivileged receive user, so it cannot hand the files
      # to another owner; remoteDir is owned by that user instead (see below).
      receiveScript = pkgs.writeShellScript "news-sync-receive" ''
        set -euo pipefail

        case "''${SSH_ORIGINAL_COMMAND:-}" in
          news.json|digest.html)
            dst="${remoteDir}/''${SSH_ORIGINAL_COMMAND}"
            tmp="$dst.tmp"
            trap '${getExe' pkgs.coreutils "rm"} -f "$tmp"' EXIT

            # Land the payload beside the target and rename over it: the
            # website reads these files at arbitrary times and must never see
            # a half-written feed.
            ${getExe' pkgs.coreutils "install"} -m 0644 /dev/stdin "$tmp"
            ${getExe' pkgs.coreutils "mv"} -f "$tmp" "$dst"
            ;;
          *)
            echo "error: unsupported news-sync command" >&2
            exit 1
            ;;
        esac
      '';

      # Stop the daemon while a gamemode session is active (the user is
      # gaming) and resume it afterwards. The desktop user only toggles a
      # marker file in /run; a root .path unit watches it via inotify and
      # runs this gate. Purely event-driven, no polling.
      newsBusyToggle = pkgs.writeShellScript "news-busy-toggle" ''
        set -euo pipefail

        if [ -e /run/news/pause ]; then
          ${config.systemd.package}/bin/systemctl stop news.service
        else
          ${config.systemd.package}/bin/systemctl start news.service
        fi
      '';

      # The daemon polls once on startup and then sleeps for its refresh
      # interval, so restarting it is what schedules a pass. Driving that from a
      # calendar timer pins the work to a chosen hour instead of letting it
      # drift from whenever the host last booted.
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
        # Pusher (epsilon): run the daemon, let the local website read the feed
        # straight from the dataDir, and push copies to the mirror host.
        (mkIf cfg.push.enable {
          services.news = {
            enable = true;

            # Every poll costs a full assessment pass on the local model, which
            # pins the GPU for hours on this machine. Daily is enough for a feed
            # whose stories are day-scale anyway, and it leaves the card free.
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

              # The daemon's uid is allocated dynamically, so it drifts whenever
              # the user gets reallocated (a flake bump did exactly that, moving
              # news from 985 to 995). It could still create files in dataDir,
              # but not truncate the ones its previous uid owned, so every write
              # failed with EACCES and the feed silently froze at the last good
              # run. Upstream's own rule only covers the directory; re-take the
              # contents on activation so a future drift heals itself.
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
                # Catch up after downtime rather than skipping a whole day, but
                # jitter it so a boot-time catch-up does not collide with login.
                Persistent = true;
                RandomizedDelaySec = "5min";
              };
            };

            services.news-busy = {
              description = "Gate news daemon on gamemode state";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = newsBusyToggle;
              };
            };

            paths.news-busy = {
              description = "React to gamemode pause marker changes";
              wantedBy = [ "multi-user.target" ];
              pathConfig.PathChanged = "/run/news/pause";
            };

            services.news-sync = {
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

        # Receiver (eta): accept the feed over WireGuard SSH and point the
        # website at the synced copy. No daemon here (no Ollama on eta).
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

          # The receive user replaces files in here, which needs write access to
          # the directory itself, not just to the files. Keep this rule byte
          # -identical to the one preservation emits below: two tmpfiles lines
          # for one path only coexist while they agree, otherwise one is
          # dropped as a duplicate and the ownership silently stays root:root.
          systemd.tmpfiles.rules = [
            "d ${remoteDir} 0755 news-sync ${cfg.receive.sshGroup} -"
          ];

          services.website.newsFile = "${remoteDir}/news.json";

          # Keep the last synced feed across reboots so the public site still
          # shows fresh-enough news when epsilon is offline. Ownership belongs
          # on the persisted directory: it is bind-mounted over remoteDir, so
          # its mode is what the receive user actually meets.
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
