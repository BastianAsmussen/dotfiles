{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.greeter;
in {
  options.desktop.greeter.gdm.enable = lib.mkEnableOption "Enables the `GDM` greeter.";

  config = lib.mkIf cfg.gdm.enable {
    services.displayManager.gdm = {
      enable = true;

      wayland = cfg.useWayland;
      autoSuspend = false;
    };
  };
}
