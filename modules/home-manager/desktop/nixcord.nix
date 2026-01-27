{inputs, ...}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;

    config = {
      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
      ];

      plugins = {
        betterGifPicker.enable = true;
        callTimer.enable = true;
        dontRoundMyTimestamps.enable = true;
        friendsSince.enable = true;
        noOnboardingDelay.enable = true;
        permissionsViewer.enable = true;
        reactErrorDecoder.enable = true;
        relationshipNotifier.enable = true;
        serverInfo.enable = true;
        showConnections.enable = true;
        showHiddenChannels.enable = true;
        showHiddenThings.enable = true;
        showTimeoutDuration.enable = true;
        validReply.enable = true;
        validUser.enable = true;
      };
    };

    extraConfig.IS_MAXIMISED = true;
  };

  stylix.targets.nixcord.enable = false;
}
