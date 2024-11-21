{
  programs.nixvim.plugins.snacks = {
    enable = true;

    settings.notifier = import ./notifier.nix;
  };
}
