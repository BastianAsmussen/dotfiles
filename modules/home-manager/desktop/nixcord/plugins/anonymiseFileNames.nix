{
  programs.nixcord.config.plugins.anonymiseFileNames = {
    enable = true;

    anonymiseByDefault = true;
    randomisedLength = 16;
  };
}
