{
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;

    settings.no_mappings = true;
    keymaps = [
      {
        action = "left";
        key = "<C-w>h";
      }
      {
        action = "down";
        key = "<C-w>j";
      }
      {
        action = "up";
        key = "<C-w>k";
      }
      {
        action = "right";
        key = "<C-w>l";
      }
      {
        action = "previous";
        key = "<C-w>\\";
      }
    ];
  };
}
