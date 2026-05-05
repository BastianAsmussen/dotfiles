{
  flake.nixosModules.greeter = {
    lib,
    pkgs,
    ...
  }: let
    niriSession = "${pkgs.niri}/share/wayland-sessions";
  in {
    services.greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --sessions ${niriSession}";
          user = "greeter";
        };

        default_session = initial_session;
      };
    };

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen.

      # Without these bootlogs will spam on screen.
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GTK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = 1;
    };
  };
}
