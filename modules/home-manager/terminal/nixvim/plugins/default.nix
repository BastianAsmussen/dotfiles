{pkgs, ...}: {
  imports = [
    ./lsp
    ./treesitter
    ./comment.nix
    ./dap.nix
    ./gitsigns.nix
    ./lualine.nix
    ./neo-tree.nix
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
      markdown-preview.enable = true;
      neocord.enable = true;
      nvim-autopairs.enable = true;
      web-devicons.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      cellular-automaton-nvim
    ];
  };
}
