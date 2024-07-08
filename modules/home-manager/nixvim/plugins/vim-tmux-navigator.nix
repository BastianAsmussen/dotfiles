{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-tmux-navigator
    ];

    keymaps = [
      {
        key = "<c-h>";
        action = "<cmd><C-U>TmuxNavigateLeft<CR>";
      }
      {
        key = "<c-j>";
        action = "<cmd><C-U>TmuxNavigateDown<CR>";
      }
      {
        key = "<c-k>";
        action = "<cmd><C-U>TmuxNavigateUp<CR>";
      }
      {
        key = "<c-l>";
        action = "<cmd><C-U>TmuxNavigateRight<CR>";
      }
      {
        key = "<c-\\>";
        action = "<cmd><C-U>TmuxNavigatePrevious<CR>";
      }
    ];
  };
}
