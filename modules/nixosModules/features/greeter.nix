{
  flake.nixosModules.greeter =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.services.displayManager) defaultSession;

      user = config.preferences.user.name;
    in
    {
      config = {
        services.displayManager.noctalia-greeter = {
          enable = true;
          passwordlessSyncUsers = [ user ];
          cursorTheme = {
            inherit (config.stylix.cursor) package name;
          };

          settings = {
            user.default = user;
            session.default = lib.mkIf (defaultSession != null) defaultSession;
            keyboard.layout = config.services.xserver.xkb.layout;
            cursor.size = config.stylix.cursor.size;
          };
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
    };
}
