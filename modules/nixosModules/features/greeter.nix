{
  flake.nixosModules.greeter =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      user = config.preferences.user.name;
      inherit (config.services.displayManager) defaultSession;
    in
    {
      config = lib.mkMerge [
        {
          services.displayManager.noctalia-greeter = {
            enable = true;

            # The polkit rule only permits this appearance sync.
            passwordlessSyncUsers = [ user ];
            cursorTheme = {
              inherit (config.stylix.cursor) package name;
            };

            settings = {
              # The greeter remembers sessions but never users.
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
        }

        # sync.toml (last session, synced palette) and synced wallpapers.
        (lib.optionalAttrs (options ? persistence) {
          persistence.directories = [
            {
              directory = "/var/lib/noctalia-greeter";
              user = "greeter";
              group = "greeter";
              mode = "0750";
            }
          ];
        })
      ];
    };
}
