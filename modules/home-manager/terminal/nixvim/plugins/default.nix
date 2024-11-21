{pkgs, ...}: {
  imports = [
    ./lsp
    ./snacks
    ./treesitter
    ./comment.nix
    ./dap.nix
    ./gitsigns.nix
    ./lualine.nix
    ./nvim-colorizer.nix
    ./telescope.nix
    ./tmux-navigator.nix
  ];

  programs.nixvim = {
    plugins = {
      bufferline.enable = true;
      crates-nvim.enable = true;
      direnv.enable = true;
      hardtime.enable = true;
      indent-blankline.enable = true;
      markdown-preview = import ./markdown-preview.nix;
      neocord.enable = true;
      noice.enable = true;
      nvim-autopairs.enable = true;
      nvim-tree = import ./nvim-tree.nix;
      web-devicons.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      cellular-automaton-nvim
      vim-be-good
    ];
  };
}
