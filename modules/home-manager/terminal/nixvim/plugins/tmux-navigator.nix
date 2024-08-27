let
  mkKeymap = action: key: {
    inherit action key;
  };
in {
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;

    settings.no_mappings = true;
    keymaps = [
      (mkKeymap "up" "<C-k>")
      (mkKeymap "down" "<C-j>")
      (mkKeymap "left" "<C-h>")
      (mkKeymap "right" "<C-l>")
      (mkKeymap "previous" "<C-\\>")
    ];
  };
}
