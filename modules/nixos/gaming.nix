{
  lib,
  config,
  pkgs,
  userInfo,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.gaming.enable = mkEnableOption "Enables gaming related settings.";

  config = mkIf config.gaming.enable {
    programs = {
      steam = {
        enable = true;

        gamescopeSession.enable = true;
      };

      gamemode.enable = true;
    };

    users.extraGroups.gamemode.members = [userInfo.username];
    environment = {
      systemPackages = with pkgs; [
        protonup-ng
        lutris
        prismlauncher
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${userInfo.username}/.steam/root/compatibilitytools.d";
    };
  };
}
