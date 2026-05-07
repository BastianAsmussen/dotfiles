{
  flake.nixosModules.primaryMirror =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        mapAttrsToList
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.primaryMirror;

      stateDir = "/var/lib/primary-mirror";
      busyFlag = "${stateDir}/busy";
      streamStateFile = "${stateDir}/stream-upstream.conf";

      upstream = "${cfg.primaryHost}:${toString cfg.primaryPort}";

      sniEntriesUp = mapAttrsToList (sni: route: "${sni} ${route.primaryAddress};") cfg.sniRoutes;
      sniEntriesDown = mapAttrsToList (
        sni: route:
        "${sni} ${if route.fallbackAddress != null then route.fallbackAddress else cfg.fallbackAddress};"
      ) cfg.sniRoutes;

      upStateFile = pkgs.writeText "stream-upstream-up.conf" (
        concatStringsSep "\n" (sniEntriesUp ++ [ "default ${upstream};" ]) + "\n"
      );

      downStateFile = pkgs.writeText "stream-upstream-down.conf" (
        concatStringsSep "\n" (sniEntriesDown ++ [ "default ${cfg.fallbackAddress};" ]) + "\n"
      );

      healthCheckScript = pkgs.writeShellScript "primary-mirror-health-check" ''
        set -euo pipefail

        if [ ! -f "${busyFlag}" ] && \
           ${lib.getExe pkgs.curl} -sf --max-time 5 \
             --resolve "${cfg.healthCheckHost}:${toString cfg.primaryPort}:${cfg.primaryHost}" \
             "https://${cfg.healthCheckHost}${cfg.healthCheckPath}" > /dev/null 2>&1; then
          target_conf="${upStateFile}"
        else
          target_conf="${downStateFile}"
        fi

        if ! cmp -s "$target_conf" "${streamStateFile}"; then
          cat "$target_conf" > "${streamStateFile}"
          ${lib.getExe' pkgs.systemd "systemctl"} reload nginx 2>/dev/null || true
        fi
      '';

      ctlScript = pkgs.writeShellScriptBin "primary-mirror-ctl" ''
        set -euo pipefail

        case "''${1:-}" in
          busy)
            touch "${busyFlag}" || {
              echo "error: permission denied, run with sudo or as ${cfg.busyUser}" >&2
              exit 1
            }
            echo "Primary marked as busy"
            ;;

          available)
            rm -f "${busyFlag}" || {
              echo "error: permission denied, run with sudo or as ${cfg.busyUser}" >&2
              exit 1
            }
            echo "Primary marked as available"
            ;;

          status)
            if [ -f "${busyFlag}" ]; then
              echo "BUSY"
            else
              echo "AVAILABLE"
            fi
            ;;

          *)
            echo "Usage: primary-mirror-ctl {busy|available|status}" >&2
            exit 1
            ;;
        esac
      '';

      busyRemoteScript = pkgs.writeShellScript "primary-mirror-remote" ''
        set -euo pipefail

        case "''${SSH_ORIGINAL_COMMAND:-}" in
          busy|available|status)
            exec ${ctlScript}/bin/primary-mirror-ctl "$SSH_ORIGINAL_COMMAND"
            ;;

          *)
            echo "error: unsupported primary-mirror command" >&2
            exit 1
            ;;
        esac
      '';
    in
    {
      options.primaryMirror = {
        enable = mkEnableOption ''
          Stream-level TLS passthrough mirror. Forwards all HTTPS traffic to the
          primary host when available, falling back to a local nginx on the
          configured fallback port otherwise.
        '';

        primaryHost = mkOption {
          type = types.str;
          default = "10.10.0.2";
          description = "WireGuard IP of the primary host.";
        };

        primaryPort = mkOption {
          type = types.port;
          default = 443;
          description = "HTTPS port on the primary host.";
        };

        fallbackAddress = mkOption {
          type = types.str;
          description = "Address (host:port) to use in the state file when the primary is unavailable or busy.";
        };

        healthCheckHost = mkOption {
          type = types.str;
          description = "Hostname used for SNI/cert verification in the health check.";
        };

        healthCheckPath = mkOption {
          type = types.str;
          default = "/";
          description = "Path to request during the health check.";
        };

        checkInterval = mkOption {
          type = types.ints.positive;
          default = 30;
          description = "How often, in seconds, to check primary host availability.";
        };

        busyUser = mkOption {
          type = types.str;
          default = "primary-busy";
          description = "SSH user allowed to update primary mirror busy state.";
        };

        busyGroup = mkOption {
          type = types.str;
          default = "primary-busy";
          description = "Group allowed to update primary mirror busy state.";
        };

        busyAuthorizedKeys = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SSH public keys allowed to update primary mirror busy state.";
        };

        sniRoutes = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                primaryAddress = mkOption {
                  type = types.str;
                  description = "Upstream (host:port) written into the state file when the primary is up.";
                };

                fallbackAddress = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Upstream (host:port) when the primary is down. Defaults to primaryMirror.fallbackAddress.";
                };
              };
            }
          );

          default = { };

          description = ''
            Per-SNI routes whose upstreams the health check controls. Each entry
            is written into the stream state file pointing to primaryAddress when
            the primary is available, and fallbackAddress (or
            primaryMirror.fallbackAddress) when it is not.
          '';
        };
      };

      config = mkIf cfg.enable {
        users = {
          groups.${cfg.busyGroup} = { };

          users.${cfg.busyUser} = {
            description = "Primary mirror busy-state controller";
            isSystemUser = true;
            createHome = false;
            group = cfg.busyGroup;
            useDefaultShell = true;
            hashedPassword = "*";

            openssh.authorizedKeys.keys = map (
              key: ''restrict,from="${cfg.primaryHost}",command="${busyRemoteScript}" ${key}''
            ) cfg.busyAuthorizedKeys;
          };
        };

        systemd = {
          tmpfiles.rules = [
            "d ${stateDir}        2775 root ${cfg.busyGroup} -"
            "C ${streamStateFile} 0644 root root             - ${downStateFile}"
          ];

          services.primary-mirror-health = {
            description = "Check primary host availability for stream passthrough";
            after = [
              "network-online.target"
              "wireguard-wg0.service"
            ];
            wants = [ "network-online.target" ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = healthCheckScript;
            };
          };

          timers.primary-mirror-health = {
            description = "Periodic primary host availability check";
            wantedBy = [ "timers.target" ];

            timerConfig = {
              OnBootSec = "15s";
              OnUnitActiveSec = "${toString cfg.checkInterval}s";
            };
          };
        };

        environment.systemPackages = [ ctlScript ];
      };
    };
}
