{
  lib,
  config,
  ...
}: {
  imports = [
    ./audio.nix
    ./sddm.nix
  ];

  options.hyprland.enable = lib.mkEnableOption "Enables Hyprland.";

  config = lib.mkIf config.hyprland.enable {
    audio.enable = true;
    sddm.enable = true;

    programs.hyprland.enable = true;
    
    # Hint Electon apps to use wayland.
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
