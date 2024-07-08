{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-tmux-navigator
    ];

    keymaps = [];
  };
}
