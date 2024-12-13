{
  inputs,
  lib,
  osConfig,
  ...
}: {
  imports = [
    inputs.schizofox.homeManagerModule
  ];

  # If we're on Wayland, tell that to Firefox.
  home.sessionVariables = lib.mkIf osConfig.desktop.greeter.useWayland {
    MOZ_ENABLE_WAYLAND = "1";
  };

  stylix.targets.firefox.enable = false;
  programs.schizofox = {
    enable = true;

    extensions = import ./extensions.nix;
    misc = import ./misc.nix;
    search.defaultSearchEngine = "DuckDuckGo";
    settings = import ./settings.nix;
    theme = import ./theme.nix osConfig;
  };
}
