{
  flake.nixosModules.gaming = {
    pkgs,
    userInfo,
    ...
  }: {
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
        bottles
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${userInfo.username}/.steam/root/compatibilitytools.d";
    };
  };
}
