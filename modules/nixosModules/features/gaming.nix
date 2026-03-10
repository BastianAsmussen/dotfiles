{
  flake.nixosModules.gaming = {
    pkgs,
    config,
    ...
  }: {
    programs = {
      steam = {
        enable = true;

        gamescopeSession.enable = true;
      };

      gamemode.enable = true;
    };

    users.extraGroups.gamemode.members = [config.preferences.user.name];
    environment = {
      systemPackages = with pkgs; [
        protonup-ng
        lutris
        bottles
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.preferences.user.name}/.steam/root/compatibilitytools.d";
    };
  };
}
