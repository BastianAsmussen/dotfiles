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

      # Use lambda only when it is not busy and its cache responds.
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
        # Create initial upstream state without overwriting the current state.
        tmpfiles.rules = [
          "d ${stateDir} 0775 root builder -"
          "f ${upstreamConf} 0644 root root - server ${lambdaAddr} down;"
        ];

        # Update upstream state and reload nginx when availability changes.
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

      # Route cache requests through the load-balanced upstream.
      nginx.reverseProxies.nix-cache = {
        upstream = lib.mkForce "http://nix_cache_backend";
        extraConfig = ''
          proxy_next_upstream error timeout http_502 http_503 http_504;
          proxy_next_upstream_timeout 10s;
          proxy_next_upstream_tries 2;
        '';
      };

      # Use lambda as the primary and local nix-serve as backup.
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
