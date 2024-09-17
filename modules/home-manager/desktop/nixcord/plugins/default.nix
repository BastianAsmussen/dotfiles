{
  imports = [
    ./anonymiseFileNames.nix
    ./betterNotesBox.nix
    ./betterRoleContext.nix
    ./implicitRelationships.nix
    ./loadingQuotes.nix
    ./replaceGoogleSearch.nix
  ];

  programs.nixcord.config.plugins = {
    alwaysAnimate.enable = true;
    crashHandler.attemptToNavigateToHome = true;
    betterGifAltText.enable = true;
    betterGifPicker.enable = true;
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
    gifPaste.enable = true;
    iLoveSpam.enable = true;
    memberCount.enable = true;
    messageLogger.enable = true;
    noOnboardingDelay.enable = true;
    permissionsViewer.enable = true;
    reactErrorDecoder.enable = true;
    relationshipNotifier.enable = true;
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
    youtubeAdblock.enable = true;
  };
}
