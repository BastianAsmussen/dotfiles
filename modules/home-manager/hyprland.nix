{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    xwayland.enable = true;

    settings = {
      "$mod" = "SUPER";

      "$terminal" = "${pkgs.alacritty}/bin/alacritty";
      "$browser" = "${pkgs.firefox}/bin/firefox";

      input.kb_layout = "dk";

      bind = [
        "$mod, RETURN, exec, $terminal"
        "$mod, F, exec, $browser"

        "$mod, Q, killactive"
        "$mod, M, exit"

        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];
    };

    extraConfig = ''
      bezier=easeOutBack,0.34,1.56,0.64,1
      bezier=easeInBack,0.36,0,0.66,-0.56
      bezier=easeInCubic,0.32,0,0.67,0
      bezier=easeInOutCubic,0.65,0,0.35,1

      animation=windowsIn,1,5,easeOutBack,popin
      animation=windowsOut,1,5,easeInBack,popin
      animation=fadeIn,0
      animation=fadeOut,1,10,easeInCubic
      animation=workspaces,1,4,easeInOutCubic,slide

      general:gaps_out=30

      xwayland {
        force_zero_scaling = true
      }
    '';
  };
}
