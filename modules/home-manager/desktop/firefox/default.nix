{
  inputs,
  osConfig,
  ...
}: {
  imports = [
    inputs.schizofox.homeManagerModule
  ];

  stylix.targets.firefox.enable = false;
  programs.schizofox = {
    enable = true;

    extensions = import ./extensions.nix;
    misc = import ./misc.nix;
    search.defaultSearchEngine = "DuckDuckGo";
    settings = import ./settings.nix;
    security.sandbox.enable = true;
    theme = import ./theme.nix osConfig;
  };
}
