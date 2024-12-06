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

    environment = {
      systemPackages = with pkgs; [
        protonup
        lutris
        bottles
        prismlauncher
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${userInfo.username}/.steam/root/compatibilitytools.d";
    };
  };
}
