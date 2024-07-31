{inputs, ...}: {
  imports = [
    inputs.nixcord.homeManagerModules.nixcord
  ];

  programs.nixcord = {
    enable = true;

    config = {
      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
      ];

      plugins = {
        alwaysAnimate.enable = true;
        betterGifAltText.enable = true;

        betterNotesBox = {
          enable = true;

          hide = true;
        };

        callTimer.enable = true;
        clearURLs.enable = true;
        copyEmojiMarkdown.enable = true;
        copyUserURLs.enable = true;
        dontRoundMyTimestamps.enable = true;
        fakeNitro.enable = true;
        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        friendsSince.enable = true;
        iLoveSpam.enable = true;
        memberCount.enable = true;
        noOnboardingDelay.enable = true;
        permissionsViewer.enable = true;
        relationshipNotifier.enable = true;

        replaceGoogleSearch = {
          enable = true;

          customEngineName = "DuckDuckGo";
          customEngineURL = "https://duckduckgo.com/?q=";
        };

        reverseImageSearch.enable = true;
        summaries.enable = true;
        serverInfo.enable = true;
        showConnections.enable = true;
        showHiddenChannels.enable = true;
        showHiddenThings.enable = true;
        showTimeoutDuration.enable = true;
        spotifyCrack.enable = true;
        validReply.enable = true;
        validUser.enable = true;
        voiceDownload.enable = true;
        watchTogetherAdblock.enable = true;
      };
    };
  };
}