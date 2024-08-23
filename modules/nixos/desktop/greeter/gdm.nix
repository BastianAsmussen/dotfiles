{
  lib,
  config,
  ...
}: {
  options.desktop.greeter.gdm.enable = lib.mkEnableOption "Enables the `GDM` greeter.";

  config = lib.mkIf config.desktop.greeter.gdm.enable {
    services.xserver = {
      enable = true;

      displayManager.gdm.enable = true;
    };
  };
}
