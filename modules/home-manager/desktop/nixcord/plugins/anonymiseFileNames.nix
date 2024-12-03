{
  programs.nixcord.config.plugins.anonymiseFileNames = {
    enable = true;

    anonymiseByDefault = false;
    randomisedLength = 8;
  };
}
