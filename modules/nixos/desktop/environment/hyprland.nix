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
    # Enable Hyprlock PAM module.
    security.pam.services.hyprlock = {};

    # Enable GNOME because Stylix will only style GDM if it's enabled, too.
    services = {
      xserver = mkIf cfg.greeter.gdm.enable {
        enable = true;

        desktopManager.gnome.enable = true;
      };

      displayManager.defaultSession = "hyprland";
    };

    environment = {
      # Since GNOME only needs to be enabled, we can strip it of all its basic features.
      gnome.excludePackages =
        mkIf cfg.greeter.gdm.enable
        (with pkgs; [
          gnome-photos
          gnome-tour
          gedit # text editor
          cheese # webcam tool
          gnome-music
          gnome-terminal
          epiphany # web browser
          geary # email reader
          evince # document viewer
          gnome-characters
          totem # video player
          tali # poker game
          iagno # go game
          hitori # sudoku game
          atomix # puzzle game
        ]);

      sessionVariables = {
        # Fix invsible cursors.
        WLR_NO_HARDWARE_CURSORS = "1";

        HYPRCURSOR_THEME = config.stylix.cursor.name;
        HYPRCURSOR_SIZE = config.stylix.cursor.size;
      };
    };

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    programs.hyprland = {
      enable = true;

      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

      xwayland.enable = true;
    };
  };
}
