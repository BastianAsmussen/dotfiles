{
  lib,
  config,
  ...
}: {
  options.hyprland.enable = lib.mkEnableOption "Enables Hyprland.";

  config = lib.mkIf config.hyprland.enable {
    services.displayManager.sddm = {
      enable = true;

      wayland.enable = true;
    };

    programs.hyprland.enable = true;
  };
}
