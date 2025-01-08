let
  mapAction = action: key: {
    inherit action key;
  };
in {
  enable = true;

  settings.no_mappings = 1;
  keymaps = [
    (mapAction "up" "<C-k>")
    (mapAction "down" "<C-j>")
    (mapAction "left" "<C-h>")
    (mapAction "right" "<C-l>")
    (mapAction "previous" "<C-\\>")
  ];
}
