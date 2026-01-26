{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkIf types;

  cfg = config.desktop;
in {
  options.desktop.environment.hyprland = {
    enable = lib.mkEnableOption "Enables the `Hyprland` desktop environment.";

    monitors = lib.mkOption {
      default = [", preferred, auto, 1"];
      description = "A list of the monitors to define.";
      type = types.listOf types.str;
    };
  };

  config = mkIf cfg.environment.hyprland.enable {
    # Enable Hyprlock PAM module.
    security.pam.services.hyprlock = {};

    # Enable GNOME because Stylix will only style GDM if it's enabled, too.
    services = {
      desktopManager.gnome.enable = cfg.greeter.gdm.enable;
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
        HYPRCURSOR_THEME = config.stylix.cursor.name;
        HYPRCURSOR_SIZE = config.stylix.cursor.size;
      };
    };

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    programs.hyprland = let
      hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = true;

      package = hyprPkgs.hyprland;
      portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;

      xwayland.enable = true;
    };

    xdg.portal = {
      enable = true;

      xdgOpenUsePortal = true;
      config = {
        common.default = ["gtk"];
        hyprland.default = ["gtk" "hyprland"];
      };

      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}
