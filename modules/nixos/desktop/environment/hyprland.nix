{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: {
  options.desktop.environment.hyprland.enable = lib.mkEnableOption "Enables the `Hyprland` desktop environment.";

  config = lib.mkIf config.desktop.environment.hyprland.enable {
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
