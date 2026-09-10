{
  flake.nixosModules.gaming =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) mkOption types concatStringsSep;

      cfg = config.gamemode;

      # gamemoded runs the custom scripts as the desktop user, so the marker
      # lives in a user-writable directory and the privileged work happens in a
      # root .path unit reacting to it. Purely event-driven, no polling.
      toggleScript = pkgs.writeShellScript "gamemode-busy-toggle" ''
        set -euo pipefail

        state="''${RUNTIME_DIRECTORY:-/run/gamemode-busy}"

        for unit in ${concatStringsSep " " cfg.pauseUnits}; do
          # Resuming must restore the state the unit was in before the game, not
          # blindly start it: several of these do heavy work on startup and a
          # unit that was already down should stay down.
          marker="$state/$unit.resume"

          if [ -e ${cfg.pauseMarker} ]; then
            if ${config.systemd.package}/bin/systemctl is-active --quiet "$unit"; then
              : > "$marker"
            else
              rm -f "$marker"
            fi

            ${config.systemd.package}/bin/systemctl stop "$unit"
          else
            [ -e "$marker" ] || continue

            rm -f "$marker"
            ${config.systemd.package}/bin/systemctl start "$unit"
          fi
        done
      '';
    in
    {
      options.gamemode = {
        startHooks = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Extra shell commands run when a gamemode session starts, in parallel
            with each other. Lets features react to gaming without fighting over
            programs.gamemode.settings.custom.
          '';
        };

        endHooks = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra shell commands run when a gamemode session ends.";
        };

        pauseUnits = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "ollama.service" ];
          description = ''
            Units stopped while a gamemode session is active and restored to
            their prior state afterwards. Each feature declares its own, so the
            list is assembled from whatever the host actually enables.
          '';
        };

        pauseMarker = mkOption {
          type = types.str;
          default = "/run/gamemode/pause";
          readOnly = true;
          description = ''
            Marker file that exists for the duration of a gamemode session.
            Features that schedule their own work can test it to avoid starting
            something mid-game.
          '';
        };
      };

      config = {
        boot = {
          # Expose /dev/ntsync so Wine/Proton can use in-kernel NT synchronization
          # primitives instead of esync/fsync emulation.
          kernelModules = [ "ntsync" ];

          kernel.sysctl = {
            # Keep game working sets in RAM; plenty of headroom before swap matters.
            "vm.swappiness" = 10;

            # Modern games/launchers mmap far beyond the kernel default.
            "vm.max_map_count" = 2147483642;
          };
        };

        programs = {
          steam = {
            enable = true;
            gamescopeSession.enable = true;
            protontricks.enable = true;

            # Unset fcitx5 IM environment variables so Proton games (XWayland)
            # receive keyboard input directly without routing through the IME,
            # which mangles non-Japanese layouts like Danish.
            package = lib.mkIf config.japanese.enable (
              pkgs.steam.overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
                postFixup = (old.postFixup or "") + ''
                  wrapProgram $out/bin/steam \
                    --unset XMODIFIERS \
                    --unset GTK_IM_MODULE \
                    --unset QT_IM_MODULE \
                    --unset SDL_IM_MODULE
                '';
              })
            );
          };

          gamemode = {
            enable = true;
            enableRenice = true;

            settings = {
              general = {
                # Only raise clocks/priority while a game is registered, instead
                # of pinning the governor to performance system-wide.
                desiredgov = "performance";
                softrealtime = "auto";
                renice = 10;
                ioprio = 0;
                inhibit_screensaver = 1;
              };

              gpu = {
                apply_gpu_optimisations = "accept-responsibility";
                gpu_device = 0;

                # NVIDIA PowerMizer: prefer maximum performance while active.
                nv_powermizer_mode = 1;
              };

              # ` & ` backgrounds every hook but the last, so a slow one (an SSH
              # notify to a sleeping host) cannot eat gamemode's 10s
              # script_timeout. The marker goes last on both sides so it is the
              # foreground command and the .path unit fires promptly.
              custom = {
                start = concatStringsSep " & " (
                  cfg.startHooks ++ [ "${lib.getExe' pkgs.coreutils "touch"} ${cfg.pauseMarker}" ]
                );

                end = concatStringsSep " & " (
                  cfg.endHooks ++ [ "${lib.getExe' pkgs.coreutils "rm"} -f ${cfg.pauseMarker}" ]
                );
              };
            };
          };

          # Available for per-game launch configs; not forced globally.
          gamescope = {
            enable = true;
            capSysNice = true;
          };
        };

        users.extraGroups.gamemode.members = [ config.preferences.user.name ];

        # Wine/Proton esync exhausts the default 1024 fd limit.
        security.pam.loginLimits = [
          {
            domain = "*";
            type = "soft";
            item = "nofile";
            value = "524288";
          }
          {
            domain = "*";
            type = "hard";
            item = "nofile";
            value = "524288";
          }
        ];

        # Wine runs unprivileged and needs direct access to the ntsync device.
        services.udev.extraRules = ''
          KERNEL=="ntsync", MODE="0666"
        '';

        systemd = {
          settings.Manager.DefaultLimitNOFILE = 524288;

          tmpfiles.rules = [
            "d ${builtins.dirOf cfg.pauseMarker} 0755 ${config.preferences.user.name} ${config.preferences.user.name} - -"
          ];

          services.gamemode-busy = {
            description = "Pause and resume units around a gamemode session";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = toggleScript;

              # The resume markers must not live next to the pause marker: the
              # .path unit watches that directory with inotify, so writing there
              # would retrigger this service in a loop.
              RuntimeDirectory = "gamemode-busy";
              RuntimeDirectoryPreserve = "yes";
            };
          };

          paths.gamemode-busy = {
            description = "React to gamemode pause marker changes";
            wantedBy = [ "multi-user.target" ];
            pathConfig.PathChanged = cfg.pauseMarker;
          };
        };

        environment = {
          systemPackages = with pkgs; [
            protonup-rs
            lutris
            bottles
            prismlauncher
            vulkan-tools
            mangohud

            # Run non-Nix binaries (game tools, mod managers) in an FHS env.
            steam-run
          ];

          sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.preferences.user.name}/.steam/root/compatibilitytools.d";
        };
      };
    };
}
