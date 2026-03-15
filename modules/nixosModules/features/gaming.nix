{inputs, ...}: {
  flake.nixosModules.gaming = {
    pkgs,
    config,
    ...
  }: {
    # Use the CachyOS gaming-focused kernel.
    boot.kernelPackages = inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-latest-lto;

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
        prismlauncher
      ];

      sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.preferences.user.name}/.steam/root/compatibilitytools.d";
    };
  };
}
