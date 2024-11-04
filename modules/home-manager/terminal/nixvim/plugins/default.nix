{
  imports = [
    ./lsp
    ./treesitter
    ./cellular-automaton.nix
    ./comment.nix
    ./dap.nix
    ./gitsigns.nix
    ./lualine.nix
    ./neo-tree.nix
    ./telescope.nix
    ./tmux-navigator.nix
  ];

  programs.nixvim.plugins = {
    bufferline.enable = true;
    crates-nvim.enable = true;
    direnv.enable = true;
    hardtime.enable = true;
    indent-blankline.enable = true;
    neocord.enable = true;
    nvim-autopairs.enable = true;
    web-devicons.enable = true;
  };
}
