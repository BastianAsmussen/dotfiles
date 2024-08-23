{
  lib,
  config,
  ...
}: {
  options.desktop.greeter.sddm.enable = lib.mkEnableOption "Enables the `SDDM` greeter.";

  config = lib.mkIf config.desktop.greeter.sddm.enable {
    services.displayManager.sddm = {
      enable = true;

      wayland.enable = true;
    };
  };
}
