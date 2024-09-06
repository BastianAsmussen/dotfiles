{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.desktop;
in {
  options.desktop.environment.hyprland.enable = mkEnableOption "Enables the `Hyprland` desktop environment.";

  config = mkIf cfg.environment.hyprland.enable {
    # Enable GNOME because Stylix will only style GDM if it's enabled, too.
    desktop.environment.gnome.enable = mkIf cfg.greeter.gdm.enable true;
    services.displayManager.defaultSession = "hyprland";

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    programs.hyprland = {
      enable = true;

      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
  };
}
