{
  lib,
  config,
  ...
}: {
  options.desktop.environment.hyprland.enable = lib.mkEnableOption "Enables the `Hyprland` desktop environment.";

  config = lib.mkIf config.desktop.environment.hyprland.enable {
    programs.hyprland.enable = true;
  };
}
