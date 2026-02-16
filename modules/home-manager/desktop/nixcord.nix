{inputs, ...}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;

    discord.enable = false;
    vesktop.enable = true;
    config = {
      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
      ];

      plugins = {
        callTimer.enable = true;
        dontRoundMyTimestamps.enable = true;
        friendsSince.enable = true;
        noOnboardingDelay.enable = true;
        relationshipNotifier.enable = true;
      };
    };

    extraConfig.IS_MAXIMISED = true;
  };

  stylix.targets.nixcord.enable = false;
}
