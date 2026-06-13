{
  inputs,
  self,
  ...
}:
{
  flake.wrapperModules.niri =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.terminal = lib.mkOption {
        type = lib.types.str;
        default = "alacritty";
      };

      config = {
        settings =
          let
            noctaliaExe = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell;

            # Capture with grim into ~/Pictures/Screenshots/<host> and also copy to the clipboard.
            mkScreenshot =
              name: grimArgs:
              lib.getExe (
                pkgs.writeShellApplication {
                  inherit name;

                  text = ''
                    dir="$HOME/Pictures/Screenshots/$(hostname)"
                    mkdir -p "$dir"

                    file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
                    ${lib.getExe pkgs.grim} ${grimArgs} "$file"
                    ${pkgs.wl-clipboard}/bin/wl-copy < "$file"
                  '';
                }
              );
          in
          {
            hotkey-overlay.skip-at-startup = _: { };
            prefer-no-csd = _: { };
            input = {
              focus-follows-mouse = _: { };
              keyboard = {
                xkb = {
                  layout = "dk";
                  options = "caps:escape";
                };

                repeat-rate = 40;
                repeat-delay = 250;
              };

              touchpad = {
                natural-scroll = _: { };
                tap = _: { };
              };

              mouse.accel-profile = "flat";
            };

            binds = {
              "Mod+Return".spawn = config.terminal;

              "Mod+Q".close-window = _: { };
              "Mod+F".maximize-window-to-edges = _: { };
              "Mod+G".fullscreen-window = _: { };
              "Mod+Shift+F".toggle-window-floating = _: { };
              "Mod+C".center-column = _: { };

              "Mod+H".focus-column-left = _: { };
              "Mod+L".focus-column-right = _: { };
              "Mod+K".focus-window-up = _: { };
              "Mod+J".focus-window-down = _: { };

              "Mod+Left".focus-column-left = _: { };
              "Mod+Right".focus-column-right = _: { };
              "Mod+Up".focus-window-up = _: { };
              "Mod+Down".focus-window-down = _: { };

              "Mod+Shift+H".move-column-left = _: { };
              "Mod+Shift+L".move-column-right = _: { };
              "Mod+Shift+K".move-window-up = _: { };
              "Mod+Shift+J".move-window-down = _: { };

              "Mod+1".focus-workspace = "w0";
              "Mod+2".focus-workspace = "w1";
              "Mod+3".focus-workspace = "w2";
              "Mod+4".focus-workspace = "w3";
              "Mod+5".focus-workspace = "w4";
              "Mod+6".focus-workspace = "w5";
              "Mod+7".focus-workspace = "w6";
              "Mod+8".focus-workspace = "w7";
              "Mod+9".focus-workspace = "w8";
              "Mod+0".focus-workspace = "w9";

              "Mod+Shift+1".move-column-to-workspace = "w0";
              "Mod+Shift+2".move-column-to-workspace = "w1";
              "Mod+Shift+3".move-column-to-workspace = "w2";
              "Mod+Shift+4".move-column-to-workspace = "w3";
              "Mod+Shift+5".move-column-to-workspace = "w4";
              "Mod+Shift+6".move-column-to-workspace = "w5";
              "Mod+Shift+7".move-column-to-workspace = "w6";
              "Mod+Shift+8".move-column-to-workspace = "w7";
              "Mod+Shift+9".move-column-to-workspace = "w8";
              "Mod+Shift+0".move-column-to-workspace = "w9";

              "Mod+Comma".focus-monitor-previous = _: { };
              "Mod+Period".focus-monitor-next = _: { };
              "Mod+Shift+Comma".move-column-to-monitor-previous = _: { };
              "Mod+Shift+Period".move-column-to-monitor-next = _: { };

              "Mod+S".spawn-sh = "${noctaliaExe} ipc call launcher toggle";
              "Mod+V".spawn-sh = "${pkgs.alsa-utils}/bin/amixer sset Capture toggle";

              "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
              "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";

              "XF86MonBrightnessUp".spawn-sh = "${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
              "XF86MonBrightnessDown".spawn-sh = "${pkgs.brightnessctl}/bin/brightnessctl set 5%-";

              "Mod+Ctrl+H".set-column-width = "-5%";
              "Mod+Ctrl+L".set-column-width = "+5%";
              "Mod+Ctrl+J".set-window-height = "-5%";
              "Mod+Ctrl+K".set-window-height = "+5%";

              "Mod+WheelScrollDown".focus-column-left = _: { };
              "Mod+WheelScrollUp".focus-column-right = _: { };
              "Mod+Ctrl+WheelScrollDown".focus-workspace-down = _: { };
              "Mod+Ctrl+WheelScrollUp".focus-workspace-up = _: { };

              "Mod+Ctrl+S".spawn-sh = mkScreenshot "screenshot-full" "-l 0";
              "Mod+Shift+E".spawn-sh = "${pkgs.wl-clipboard}/bin/wl-paste | ${lib.getExe pkgs.swappy} -f -";
              "Mod+Shift+S".spawn-sh = mkScreenshot "screenshot-region" ''-g "$(${lib.getExe pkgs.slurp} -w 0)"'';

              "Mod+d".spawn-sh = self.mkWhichKeyExe pkgs [
                {
                  key = "b";
                  desc = "Bluetooth";
                  cmd = "${noctaliaExe} ipc call bluetooth togglePanel";
                }
                {
                  key = "w";
                  desc = "Wifi";
                  cmd = "${noctaliaExe} ipc call wifi togglePanel";
                }
                {
                  key = "f";
                  desc = "Firefox";
                  cmd = "schizofox";
                }
                {
                  key = "d";
                  desc = "Discord";
                  cmd = "vesktop";
                }
                {
                  key = "s";
                  desc = "Pavucontrol";
                  cmd = "${lib.getExe pkgs.pavucontrol}";
                }
                {
                  key = "l";
                  desc = "Lock Screen";
                  cmd = "${noctaliaExe} ipc call lockScreen lock";
                }
              ];
            };

            layout = {
              gaps = 5;
              focus-ring = {
                width = 2;
                active-color = "#${self.themeNoHash.base0D}";
              };
            };

            layer-rules = [
              {
                matches = [ { namespace = "^noctalia-overview*"; } ];
                place-within-backdrop = true;
              }
            ];

            window-rules = [
              {
                excludes = [ { is-floating = true; } ];
                clip-to-geometry = true;
                geometry-corner-radius = 10.0;
              }
              {
                matches = [ { app-id = "steam"; } ];
                excludes = [ { title = "^[Ss]team$"; } ];
                open-floating = true;
              }
              {
                matches = [
                  {
                    app-id = "steam";
                    title = "^notificationtoasts_\\d+_desktop$";
                  }
                ];

                default-floating-position = _: {
                  props = {
                    x = 10;
                    y = 10;
                    relative-to = "bottom-right";
                  };
                };

                open-focused = false;
              }
              {
                matches = [ { title = "^Picture-in-Picture$"; } ];

                open-floating = true;
                open-focused = false;

                min-width = 480;
                max-width = 480;
                min-height = 270;
                max-height = 270;

                default-floating-position = _: {
                  props = {
                    x = 10;
                    y = 10;
                    relative-to = "bottom-right";
                  };
                };
              }
              {
                # Enable VRR for games.
                matches = [ { app-id = "^steam_app_"; } ];
                variable-refresh-rate = true;
              }
            ];

            workspaces =
              let
                settings = {
                  layout.gaps = 5;
                };
              in
              {
                "w0" = settings;
                "w1" = settings;
                "w2" = settings;
                "w3" = settings;
                "w4" = settings;
                "w5" = settings;
                "w6" = settings;
                "w7" = settings;
                "w8" = settings;
                "w9" = settings;
              };

            xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;
          };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;

        imports = [ self.wrapperModules.niri ];
      };
    };
}
