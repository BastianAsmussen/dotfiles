{
  config,
  lib,
  nixosConfig,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types mkIf mkForce;
  inherit (builtins) concatLists genList toString;

  cfg = {
    inherit (config) hyprland;
    inherit (config.lib.stylix) colors;
  };
in {
  options.hyprland.monitors = mkOption {
    default = [
      "DP-1, 1920x1080@240, 0x0, 1"
      "HDMI-A-1, 1920x1080, 1920x0, 1"
      ", preferred, auto, 1" # Recommended rule for quickly plugging in random monitors.
    ];
    description = "The monitors to use for Hyprland.";
    type = types.listOf types.str;
  };

  config = mkIf nixosConfig.desktop.environment.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;

      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      xwayland.enable = true;
      settings = {
        exec-once = "${pkgs.ags}/bin/ags";
        "$mod" = "SUPER";
        "$terminal" = "alacritty";
        "$browser" = "firefox";
        input.kb_layout = "dk";
        monitor = cfg.hyprland.monitors;
        bind =
          [
            "$mod, RETURN, exec, $terminal"
            "$mod, F, exec, $browser"

            "$mod, Q, killactive"
            "$mod, M, exit"
            "$mod SHIFT, F, fullscreen, 1"

            "$mod, H, movefocus, l"
            "$mod, L, movefocus, r"
            "$mod, K, movefocus, u"
            "$mod, J, movefocus, d"
          ]
          ++ (
            concatLists (genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
          "$mod ALT, mouse:272, resizewindow"
        ];

        general = {
          "col.active_border" = mkForce "rgba(${cfg.colors.base0E}ff) rgba(${cfg.colors.base09}ff) 60deg";
          "col.inactive_border" = mkForce "rgba(${cfg.colors.base00}ff)";

          gaps_out = 30;
        };
      };

      extraConfig = ''
        bezier = easeOutBack, 0.34, 1.56, 0.64, 1
        bezier = easeInBack, 0.36, 0, 0.66, -0.56
        bezier = easeInCubic, 0.32, 0, 0.67 ,0
        bezier = easeInOutCubic, 0.65, 0, 0.35, 1

        animation = windowsIn, 1, 5, easeOutBack, popin
        animation = windowsOut, 1, 5, easeInBack, popin
        animation = fadeIn, 0
        animation = fadeOut, 1, 10, easeInCubic
        animation = workspaces, 1, 4, easeInOutCubic, slide

        xwayland:force_zero_scaling = true
      '';
    };
  };
}
