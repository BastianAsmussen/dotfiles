{
  lib,
  config,
  ...
}: {
  options.gnome.enable = lib.mkEnableOption "Enables Gnome.";

  config = lib.mkIf config.gnome.enable {
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
