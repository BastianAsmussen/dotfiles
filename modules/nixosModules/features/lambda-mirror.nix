{
  flake.nixosModules.lambdaMirror = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.lambdaMirror;

    stateDir = "/var/lib/lambda-mirror";
    upstreamConf = "${stateDir}/upstream-state.conf";
    busyFlag = "${stateDir}/busy";

    lambdaAddr = "${cfg.lambdaHost}:${toString cfg.lambdaPort}";

    healthCheckScript = pkgs.writeShellScript "lambda-mirror-health-check" ''
      set -euo pipefail

      # Lambda is available only when it is not marked as busy AND its
      # nix-serve endpoint is reachable.
      if [ ! -f "${busyFlag}" ] && \
         ${lib.getExe pkgs.curl} -sf --max-time 5 \
           "http://${lambdaAddr}/nix-cache-info" > /dev/null 2>&1; then
        new_state="server ${lambdaAddr};"
      else
        new_state="server ${lambdaAddr} down;"
      fi

      old_state=""
      if [ -f "${upstreamConf}" ]; then
        old_state=$(cat "${upstreamConf}")
      fi

      if [ "$new_state" != "$old_state" ]; then
        echo "$new_state" > "${upstreamConf}"
        ${lib.getExe' pkgs.systemd "systemctl"} reload nginx 2>/dev/null || true
      fi
    '';

    ctlScript = pkgs.writeShellScriptBin "lambda-mirror-ctl" ''
      case "''${1:-}" in
        busy)
          touch "${busyFlag}"
          echo "Lambda marked as busy"
          ;;
        available)
          rm -f "${busyFlag}"
          echo "Lambda marked as available"
          ;;
        status)
          if [ -f "${busyFlag}" ]; then
            echo "BUSY"
          else
            echo "AVAILABLE"
          fi
          ;;
        *)
          echo "Usage: lambda-mirror-ctl {busy|available|status}" >&2
          exit 1
          ;;
      esac
    '';
  in {
    options.lambdaMirror = {
      enable = mkEnableOption ''
        Mirror/load-balancer for lambda's nix cache.  When enabled, nginx
        proxies to lambda's nix-serve when it is available and falls back to
        the local cache when lambda is offline or marked as busy.
      '';

      lambdaHost = mkOption {
        type = types.str;
        default = "lambda";
        description = "Tailscale hostname or IP address of the lambda machine.";
      };

      lambdaPort = mkOption {
        type = types.port;
        default = 5000;
        description = "Port of nix-serve on the lambda machine.";
      };

      checkInterval = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "How often (in seconds) to check lambda's availability.";
      };
    };

    config = mkIf cfg.enable {
      systemd = {
        # Ensure the state directory and initial upstream config exist before
        # nginx starts.  The `f` type only creates the file when it is missing,
        # preserving the current state across reboots.
        tmpfiles.rules = [
          "d ${stateDir} 0775 root builder -"
          "f ${upstreamConf} 0644 root root - server ${lambdaAddr} down;"
        ];

        # Periodic health check that updates the upstream state file and
        # reloads nginx when the state changes.
        services.lambda-mirror-health = {
          description = "Check lambda availability for the nix cache mirror";
          after = ["network-online.target" "tailscaled.service"];
          wants = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = healthCheckScript;
          };
        };

        timers.lambda-mirror-health = {
          description = "Periodic lambda availability check";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "15s";
            OnUnitActiveSec = "${toString cfg.checkInterval}s";
          };
        };
      };

      # Point the nix-cache reverse proxy at the load-balanced upstream
      # instead of directly at the local nix-serve.
      nginx.reverseProxies.nix-cache = {
        upstream = lib.mkForce "http://nix_cache_backend";
        extraConfig = ''
          proxy_next_upstream error timeout http_502 http_503 http_504;
          proxy_next_upstream_timeout 10s;
          proxy_next_upstream_tries 2;
        '';
      };

      # The upstream block lives in the http context.  Lambda is the primary
      # server (toggled via an included state file) and the local nix-serve
      # instance acts as the backup.
      services.nginx.appendHttpConfig = ''
        upstream nix_cache_backend {
          include ${upstreamConf};
          server 127.0.0.1:${toString config.services.nix-serve.port} backup;
        }
      '';

      # Control script for toggling the busy state.
      environment.systemPackages = [ctlScript];
    };
  };
}
