{
  lib,
  config,
  ...
}: {
  options.desktop.environment.gnome.enable = lib.mkEnableOption "Enables the `GNOME` desktop environment.";

  config = lib.mkIf config.desktop.environment.gnome.enable {
    services.xserver.desktopManager.gnome.enable = true;
  };
}
