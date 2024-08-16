{
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;

    settings.no_mappings = true;
    keymaps = [
      {
        action = "left";
        key = "<C-h>";
      }
      {
        action = "down";
        key = "<C-j>";
      }
      {
        action = "up";
        key = "<C-k>";
      }
      {
        action = "right";
        key = "<C-l>";
      }
      {
        action = "previous";
        key = "<C-\\>";
      }
    ];
  };
}
