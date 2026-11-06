{
  flake.nixosModules.primaryBusy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.primaryBusy;

      systemctl = lib.getExe' config.systemd.package "systemctl";
      unit = "primary-available.socket";

      syncScript = pkgs.writeShellScript "primary-busy-sync" ''
        if [ -n "$(${lib.getExe' pkgs.gamemode "gamemodelist"} 2>/dev/null)" ]; then
          ${systemctl} stop ${unit}
        else
          ${systemctl} start ${unit}
        fi
      '';
    in
    {
      options.primaryBusy = {
        enable = mkEnableOption ''
          Close the availability port the mirror health-checks while gamemode is
          active, so the mirror stops proxying traffic here
        '';

        mirrorHost = mkOption {
          type = types.str;
          default = "10.10.0.1";
          description = "WireGuard address of the mirror host, the only source allowed to probe.";
        };

        address = mkOption {
          type = types.str;
          default = "10.10.0.2";
          description = "WireGuard address the availability port listens on.";
        };

        port = mkOption {
          type = types.port;
          default = 9444;
          description = "Availability port; must match the mirror's primaryMirror.availabilityPort.";
        };

        syncInterval = mkOption {
          type = types.ints.positive;
          default = 60;
          description = "How often, in seconds, to reconcile the port with gamemode state.";
        };
      };

      config = mkIf cfg.enable {
        # Use hooks immediately and a timer as backup.
        gamemode = {
          startHooks = [ "${systemctl} stop ${unit}" ];
          endHooks = [ "${systemctl} start ${unit}" ];
        };

        # Only let the user start and stop this unit.
        security.polkit.extraConfig = ''
          polkit.addRule(function (action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "${unit}" &&
                (action.lookup("verb") == "start" || action.lookup("verb") == "stop") &&
                subject.user == "${config.preferences.user.name}") {
              return polkit.Result.YES;
            }
          });
        '';

        networking.firewall.extraInputRules = ''
          iifname "wg0" ip saddr ${cfg.mirrorHost} tcp dport ${toString cfg.port} accept
        '';

        systemd = {
          sockets.primary-available = {
            description = "Availability probe for the mirror";
            wantedBy = [ "sockets.target" ];
            listenStreams = [ "${cfg.address}:${toString cfg.port}" ];
            socketConfig = {
              Accept = true;
              FreeBind = true;
            };
          };

          services = {
            "primary-available@" = {
              description = "Close an availability probe";
              serviceConfig = {
                ExecStart = lib.getExe' pkgs.coreutils "true";
                StandardInput = "socket";
              };
            };

            primary-busy-sync = {
              description = "Reconcile the availability port with gamemode state";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = syncScript;
              };
            };
          };

          timers.primary-busy-sync = {
            description = "Periodic availability reconciliation";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "30s";
              OnUnitActiveSec = "${toString cfg.syncInterval}s";
            };
          };
        };
      };
    };
}
