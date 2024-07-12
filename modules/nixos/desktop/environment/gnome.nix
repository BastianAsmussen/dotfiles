{
  lib,
  config,
  ...
}: {
  options.gnome.enable = lib.mkEnableOption "Enables Gnome.";

  config = lib.mkIf config.gnome.enable {
    services.xserver.desktopManager.gnome.enable = true;
  };
}
