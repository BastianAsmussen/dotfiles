{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  inherit (lib) getExe mkIf;
  inherit (builtins) genList toString;

  playerctl = getExe pkgs.playerctl;
  brightnessctl = getExe pkgs.brightnessctl;
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  screenshot = import ./scripts/screenshot.nix {inherit pkgs lib;};

  smartGaps = {
    windowrule = [
      "border_size 0, match:float 0, match:workspace w[t1]"
      "rounding 0, match:float 0, match:workspace w[t1]"
      "border_size 0, match:float 0, match:workspace w[tg1]"
      "rounding 0, match:float 0, match:workspace w[tg1]"
      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"
    ];

    workspace = [
      "w[t1], gapsout:0, gapsin:0"
      "w[tg1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];
  };
in {
  imports = [
    ./ags
    ./hyprlock.nix
  ];

  config = mkIf osConfig.desktop.environment.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      inherit (osConfig.programs.hyprland) package;

      xwayland.enable = true;
      systemd.enableXdgAutostart = true;
      settings = {
        exec-once = ["ags -b hypr"];
        "$mod" = "SUPER";

        input = let
          xkbCfg = osConfig.services.xserver.xkb;
        in {
          kb_layout = xkbCfg.layout;
          kb_variant = xkbCfg.variant;
          kb_options = xkbCfg.options;

          follow_mouse = 1;
          touchpad = {
            natural_scroll = "yes";
            disable_while_typing = true;
            drag_lock = true;
          };

          sensitivity = 0;
          float_switch_override_focus = 2;

          # Disable mouse acceleration if gaming is enabled.
          accel_profile = "flat";
          force_no_accel = !osConfig.gaming.enable;
        };

        monitor = osConfig.desktop.environment.hyprland.monitors;
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        gesture = ["3, horizontal, workspace,"];
        misc = {
          disable_splash_rendering = true;
          force_default_wallpaper = 1;
        };

        windowrule = let
          pictureInPicture = "match:class (firefox) match:title ^(Picture-in-Picture)$";
          mullvadVPN = "match:class (Mullvad VPN)";
          steam = "match:class (steam)";

          mkFloating = pattern: "match:title ^(${pattern})$, float on";
        in
          lib.mkMerge [
            smartGaps.windowrule
            [
              "${pictureInPicture}, float on"
              "${pictureInPicture}, size 30% 30%"
              "${pictureInPicture}, move 100%-w-20"
              "${pictureInPicture}, pin on"
              "${pictureInPicture}, keep_aspect_ratio on"
              "match:class (org.qbittorrent.qBittorrent) match:title ^(?!qBittorrent).*$, float on"
              "match:class (electron) match:title ^(?!electron).*$, float on"

              (mkFloating "org.gnome.Calculator")
              (mkFloating "org.gnome.Nautilus")
              (mkFloating "org.pulseaudio.pavucontrol")
              (mkFloating "nm-connection-editor")
              (mkFloating "org.gnome.Settings")
              (mkFloating "org.gnome.design.Palette")
              (mkFloating "Color Picker")
              (mkFloating "xdg-desktop-portal")
              (mkFloating "xdg-desktop-portal-gtk")
              (mkFloating "xdg-desktop-portal-gnome")
              (mkFloating "virt-manager")
              (mkFloating "org.gnome.World.PikaBackup")
              (mkFloating "org.gnome.Weather")
              (mkFloating "com.github.Aylur.ags")
            ]
            (mkIf osConfig.vpn.enable [
              "${mullvadVPN}, float on"
              "${mullvadVPN}, move 100%-w-20 5%"
              "${mullvadVPN}, pin on"
            ])
            (mkIf osConfig.gaming.enable [
              "${steam} match:title ^(?!Steam$).*$, float on"
              "${steam} match:title Friends List, size 15% 60%"
              "${steam} match:title Friends List, center on"

              "match:class (steam_app_default), match:title (Overwatch), content game"

              "match:tag game, fullscreen on"
              "match:tag game, immediate on"
              "match:tag game, no_vrr off"
              "match:tag game, content game"
            ])
          ];

        inherit (smartGaps) workspace;

        binds.allow_workspace_cycles = true;
        bind = let
          mkBind = mod: cmd: key: arg: "${mod}, ${key}, ${cmd}, ${arg}";

          mkWorkspaceBind = mkBind "$mod" "workspace";
          mkMoveFocusBind = mkBind "$mod" "movefocus";
          mkResizeActiveBind = mkBind "$mod CTRL" "resizeactive";
          mkMoveActiveBind = mkBind "$mod ALT" "moveactive";
          mkMoveToWorkspaceBind = mkBind "$mod SHIFT" "movetoworkspace";

          workspaceList = genList (x: x + 1) 9;

          ags = "exec, ags -b hypr";
        in
          [
            "CTRL SHIFT, r, ${ags} quit; ags -b hypr"

            "$mod, r, ${ags} -t launcher"
            "$mod, Tab, ${ags} -t overview"

            ",XF86PowerOff, ${ags} -r 'powermenu.shutdown()'"

            ",Home , exec, ${getExe screenshot}"
            "SHIFT, Home, exec, ${getExe screenshot} --full"

            "$mod, Return, exec, alacritty"
            "$mod, w, exec, firefox"
            "$mod, Backspace, exec, hyprlock"

            "ALT, Tab, focuscurrentorlast"
            "CTRL ALT, Delete, exit"
            "ALT, q, killactive"

            "$mod, f, togglefloating"
            "$mod, g, fullscreen"
            "$mod, SHIFT g, tagwindow, game" # Mark as a game.
            "$mod, o, fullscreen, 1" # Fake fullscreen.
            "$mod, p, togglesplit"

            (mkMoveFocusBind "h" "l")
            (mkMoveFocusBind "j" "d")
            (mkMoveFocusBind "k" "u")
            (mkMoveFocusBind "l" "r")

            (mkWorkspaceBind "left" "e-1")
            (mkWorkspaceBind "right" "e+1")

            (mkResizeActiveBind "h" "-20 0")
            (mkResizeActiveBind "j" "0 20")
            (mkResizeActiveBind "k" "0 -20")
            (mkResizeActiveBind "l" "20 0")

            (mkMoveActiveBind "h" "-20 0")
            (mkMoveActiveBind "j" "0 20")
            (mkMoveActiveBind "k" "0 -20")
            (mkMoveActiveBind "l" "20 0")
          ]
          ++ (map (i: mkWorkspaceBind (toString i) (toString i)) workspaceList)
          ++ (map (i: mkMoveToWorkspaceBind (toString i) (toString i)) workspaceList);

        bindle = [
          ",XF86MonBrightnessUp, exec, ${brightnessctl} set +5%"
          ",XF86MonBrightnessDown, exec, ${brightnessctl} set -5%"
          ",XF86KbdBrightnessUp, exec, ${brightnessctl} -d *::kbd_backlight set +33%"
          ",XF86KbdBrightnessDown, exec, ${brightnessctl} -d *::kbd_backlight set +33%"
          ",XF86AudioRaiseVolume, exec, ${pactl} set-sink-volume @DEFAULT_SINK@ +5%"
          ",XF86AudioLowerVolume, exec, ${pactl} set-sink-volume @DEFAULT_SINK@ -5%"
        ];

        bindl = [
          ",XF86AudioPlay, exec, ${playerctl} play-pause"
          ",XF86AudioStop, exec, ${playerctl} pause"
          ",XF86AudioPause, exec, ${playerctl} pause"
          ",XF86AudioPrev, exec, ${playerctl} previous"
          ",XF86AudioNext, exec, ${playerctl} next"
          ",XF86AudioMute, exec, ${pactl} set-sink-mute @DEFAULT_SINK@ toggle"
          ",XF86AudioMicMute, exec, ${pactl} set-source-mute @DEFAULT_SOURCE@ toggle"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        general = {
          layout = "dwindle";
          resize_on_border = true;
        };

        decoration = {
          rounding = 12;
          dim_inactive = false;
          shadow = {
            enabled = true;
            range = 8;
            render_power = 2;
            color = lib.mkForce "rgba(00000044)";
          };

          blur = {
            enabled = true;
            size = 8;
            passes = 3;
            new_optimizations = "on";
            noise = 0.01;
            contrast = 0.9;
            brightness = 0.8;
            popups = true;
          };
        };

        animations = {
          enabled = "yes";
          bezier = "smoothing, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 5, smoothing"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        plugin = {
          overview = {
            centerAligned = true;
            hideTopLayers = true;
            hideOverlayLayers = true;
            showNewWorkspace = true;
            exitOnClick = true;
            exitOnSwitch = true;
            drawActiveWorkspace = true;
            reverseSwipe = true;
          };

          hyprbars = {
            bar_color = "rgb(2a2a2a)";
            bar_height = 28;
            col_text = "rgba(ffffffdd)";
            bar_text_size = 11;
            bar_text_font = "Ubuntu Nerd Font";

            buttons = {
              button_size = 0;
              "col.maximize" = "rgba(ffffff11)";
              "col.close" = "rgba(ff111133)";
            };
          };
        };

        ecosystem.no_donation_nag = true;
        xwayland.force_zero_scaling = true;
      };
    };

    services.hyprpaper.settings.splash = false;
  };
}
