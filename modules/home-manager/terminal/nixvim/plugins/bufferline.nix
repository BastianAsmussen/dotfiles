{
  programs.nixvim = {
    plugins.bufferline.enable = true;

    keymaps = [
      {
        mode = "n";
        key = "<Tab>";
        action = "<cmd>BufferLineCycleNext<CR>";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action = "<cmd>BufferLineCyclePrev<CR>";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = "<cmd>bdelete!<CR>";
      }
    ];
  };
}
