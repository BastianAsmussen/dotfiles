{
  lib,
  config,
  ...
}: {
  options.desktop.environment.gnome.enable = lib.mkEnableOption "Enables the `Gnome` desktop environment.";

  config = lib.mkIf config.desktop.environment.gnome.enable {
    services.xserver.desktopManager.gnome.enable = true;

    # Prevent hibernation.
    security.polkit = {
      enable = true;

      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.suspend" ||
              action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
              action.id == "org.freedesktop.login1.hibernate" ||
              action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
          {
              return polkit.Result.NO;
          }
        });
      '';
    };
  };
}
