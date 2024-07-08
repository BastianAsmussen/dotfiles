{
  lib,
  config,
  ...
}: {
  options.hyprland.enable = lib.mkEnableOption "Enables Hyprland.";

  config = lib.mkIf config.hyprland.enable {
    services.xserver = {
      enable = true;
      xkb.layout = "dk";

      displayManager.gdm.enable = true;
    };

    programs.hyprland.enable = true;
  };
}
