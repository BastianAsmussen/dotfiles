{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.greeter;
in {
  options.desktop.greeter.sddm.enable = lib.mkEnableOption "Enables the `SDDM` greeter.";

  config = lib.mkIf cfg.sddm.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = cfg.useWayland;
    };
  };
}
