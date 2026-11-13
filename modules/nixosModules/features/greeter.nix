{
  flake.nixosModules.greeter =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      inherit (config.services.displayManager) defaultSession;

      user = config.preferences.user.name;
      greeterUser = config.services.greetd.settings.default_session.user;
    in
    {
      config = lib.mkMerge [
        {
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
              appearance = {
                scheme = "Catppuccin";
                hide_logo = true;
                wallpaper = {
                  path = config.stylix.image;
                  fill_mode = "crop";
                };
              };
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
        }

        # Sync and login-screen state (sync.toml, synced wallpapers).
        (lib.optionalAttrs (options ? persistence) {
          persistence.directoriesWithMode."/var/lib/noctalia-greeter" = {
            mode = "0750";
            user = greeterUser;
            group = config.users.users.${greeterUser}.group;
          };
        })
      ];
    };
}
