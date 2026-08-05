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

      # The forced command accepts only the two feed files from the primary
      # host.
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

      # A root .path unit watches the user's pause marker without polling.
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

          # Persist the latest feed while epsilon is offline.
          persistence.directories = [ remoteDir ];
        })
      ];
    };
}
