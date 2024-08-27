{
  imports = [
    ./lsp
    ./auto-save.nix
    ./cellular-automaton.nix
    ./dashboard.nix
    ./gitsigns.nix
    ./lualine.nix
    ./neo-tree.nix
    ./telescope.nix
    ./tmux-navigator.nix
    ./treesitter.nix
  ];

  programs.nixvim.plugins = {
    bufferline.enable = true;
    direnv.enable = true;
    nvim-autopairs.enable = true;
  };
}
