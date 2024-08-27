{
  programs.nixcord.config.plugins.replaceGoogleSearch = {
    enable = true;

    customEngineName = "DuckDuckGo";
    customEngineURL = "https://duckduckgo.com/?q=";
  };
}
