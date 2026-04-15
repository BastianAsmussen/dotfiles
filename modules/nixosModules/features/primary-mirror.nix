{
  flake.nixosModules.primaryMirror = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.primaryMirror;

    stateDir = "/var/lib/primary-mirror";
    busyFlag = "${stateDir}/busy";

    # nginx upstream identifiers must not contain hyphens.
    upstreamName = name: "primary_mirror_${builtins.replaceStrings ["-"] ["_"] name}";
    upstreamConf = name: "${stateDir}/${name}.conf";

    serviceList = lib.mapAttrsToList (name: value: {inherit name value;}) cfg.services;

    healthCheckUrl =
      if cfg.healthCheck != null
      then cfg.healthCheck
      else "http://${cfg.primaryHost}:5000/nix-cache-info";

    healthCheckScript = pkgs.writeShellScript "primary-mirror-health-check" ''
      set -euo pipefail

      if [ ! -f "${busyFlag}" ] && \
         ${lib.getExe pkgs.curl} -sf --max-time 5 "${healthCheckUrl}" > /dev/null 2>&1; then
        state="up"
      else
        state="down"
      fi

      changed=0
      ${lib.concatMapStrings ({
          name,
          value,
        }: let
          addr = "${cfg.primaryHost}:${toString value.primaryPort}";
          conf = upstreamConf name;
        in ''
          if [ "$state" = "up" ]; then
            new_conf="server ${addr};"
          else
            new_conf="server ${addr} down;"
          fi
          old_conf=""
          [ -f "${conf}" ] && old_conf=$(cat "${conf}")
          if [ "$new_conf" != "$old_conf" ]; then
            echo "$new_conf" > "${conf}"
            changed=1
          fi
        '')
        serviceList}

      if [ "$changed" -eq 1 ]; then
        ${lib.getExe' pkgs.systemd "systemctl"} reload nginx 2>/dev/null || true
      fi
    '';

    ctlScript = pkgs.writeShellScriptBin "primary-mirror-ctl" ''
      set -euo pipefail
      case "''${1:-}" in
        busy)
          touch "${busyFlag}" || { echo "error: permission denied, run with sudo" >&2; exit 1; }
          echo "Primary marked as busy"
          ;;
        available)
          rm -f "${busyFlag}" || { echo "error: permission denied, run with sudo" >&2; exit 1; }
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
  in {
    options.primaryMirror = {
      enable = mkEnableOption ''
        Mirror/proxy for remote services.  When enabled, nginx routes each
        registered service to the primary host when it is available and not
        busy, falling back to a local instance otherwise.
      '';

      primaryHost = mkOption {
        type = types.str;
        default = "10.10.0.2";
        description = "WireGuard IP address of the primary host.";
      };

      healthCheck = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          URL polled to determine the primary host's availability.  Defaults
          to the nix-cache health endpoint when null.
        '';
      };

      checkInterval = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "How often (in seconds) to check the primary host's availability.";
      };

      services = mkOption {
        default = {};
        description = "Services to mirror from the primary host with local fallback.";
        type = types.attrsOf (types.submodule ({name, ...}: {
          options = {
            nginxProxy = mkOption {
              type = types.str;
              default = name;
              description = "Key in nginx.reverseProxies to override with the mirrored upstream.";
            };

            primaryPort = mkOption {
              type = types.port;
              description = "Port the service listens on on the primary host.";
            };

            localFallback = mkOption {
              type = types.str;
              description = "Local upstream address (host:port) served as backup when the primary host is unavailable.";
            };
          };
        }));
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.services != {};
          message = "primaryMirror.enable = true but primaryMirror.services is empty.";
        }
      ];

      systemd = {
        tmpfiles.rules =
          ["d ${stateDir} 0775 root builder -"]
          ++ map (
            {
              name,
              value,
            }: let
              addr = "${cfg.primaryHost}:${toString value.primaryPort}";
            in "f ${upstreamConf name} 0644 root root - server ${addr} down;"
          )
          serviceList;

        services.primary-mirror-health = {
          description = "Check primary host availability for mirrored services";
          after = ["network-online.target" "wireguard-wg0.service"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = healthCheckScript;
          };
        };

        timers.primary-mirror-health = {
          description = "Periodic primary host availability check";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "15s";
            OnUnitActiveSec = "${toString cfg.checkInterval}s";
          };
        };
      };

      # Override each registered proxy's upstream with the mirrored backend.
      nginx.reverseProxies =
        lib.mapAttrs' (_: svc: {
          name = svc.nginxProxy;
          value = {
            upstream = lib.mkForce "http://${upstreamName svc.nginxProxy}";
            extraConfig = lib.mkDefault ''
              proxy_next_upstream error timeout http_502 http_503 http_504;
              proxy_next_upstream_timeout 10s;
              proxy_next_upstream_tries 2;
            '';
          };
        })
        cfg.services;

      # One nginx upstream block per service: primary as active (toggled via
      # the included state file), local instance as backup.
      services.nginx.appendHttpConfig =
        lib.concatMapStrings ({
          name,
          value,
        }: ''
          upstream ${upstreamName value.nginxProxy} {
            include ${upstreamConf name};
            server ${value.localFallback} backup;
          }
        '')
        serviceList;

      environment.systemPackages = [ctlScript];
    };
  };
}
