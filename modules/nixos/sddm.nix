{
  lib,
  config,
  ...
}: {
  options.sddm.enable = lib.mkEnableOption "Enable SDDM.";

  config = lib.mkIf config.sddm.enable {
    security.polkit.enable = true;

    services.displayManager.sddm = {
      enable = true;

      wayland.enable = true;
    };
  };
}
