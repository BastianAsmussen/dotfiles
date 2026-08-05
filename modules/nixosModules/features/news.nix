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
      remoteDir = cfg.remoteDir;

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
      receiveScript = pkgs.writeShellScript "news-sync-receive" ''
        set -euo pipefail

        case "''${SSH_ORIGINAL_COMMAND:-}" in
          news.json|digest.html)
            ${getExe' pkgs.coreutils "install"} -m 0644 -o root -g ${cfg.receive.sshGroup} \
              /dev/stdin "${remoteDir}/''${SSH_ORIGINAL_COMMAND}"
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
          services.news.enable = true;
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
            ];

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

          systemd.tmpfiles.rules = [
            "d ${remoteDir} 0755 root ${cfg.receive.sshGroup} -"
          ];

          services.website.newsFile = "${remoteDir}/news.json";

          # Keep the last synced feed across reboots so the public site still
          # shows fresh-enough news when epsilon is offline.
          persistence.directories = [ remoteDir ];
        })
      ];
    };
}
