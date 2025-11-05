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
      gamemode.enable = true;
      steam = {
        enable = true;

        gamescopeSession = {
          enable = true;

          env = {
            WLR_RENDERER = "vulkan";
            DXVK_HDR = "1";
            ENABLE_GAMESCOPE_WSI = "1";
            WINE_FULLSCREEN_FSR = "1";

            # Games allegedly prefer X11.
            SDL_VIDEODRIVER = "x11";
          };

          args = [
            "--xwayland-count 2"
            "--expose-wayland"

            "-e" # Enable steam integration.
            "--adaptive-sync"

            # Monitor Setup.
            "--prefer-output DP-1"
            "--output-width 1920"
            "--output-height 1080"
            "-r 240"

            # GPU Setup.
            "--prefer-vk-device" # `lspci -nn | grep VGA`
            "10de:2782" # Dedicated GPU.
          ];
        };
      };
    };

    users.extraGroups.gamemode.members = [userInfo.username];
    environment = {
      systemPackages = with pkgs; [
        protonup-ng
        lutris
        bottles
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${userInfo.username}/.steam/root/compatibilitytools.d";
    };
  };
}
