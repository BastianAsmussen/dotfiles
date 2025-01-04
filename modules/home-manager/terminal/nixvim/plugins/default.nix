{
  config,
  osConfig,
  lib,
  userInfo,
  pkgs,
  ...
}: {
  imports = [
    ./snacks
    ./cmp.nix
    ./comment.nix
    ./dap.nix
    ./nvim-autopairs.nix
    ./telescope.nix
    ./tmux-navigator.nix
  ];

  programs.nixvim = {
    plugins = {
      crates.enable = true;
      colorizer = import ./colorizer.nix;
      direnv.enable = true;
      fidget.enable = true;
      gitsigns = import ./gitsigns.nix config;
      hardtime.enable = true;
      indent-blankline.enable = true;
      lsp = import ./lsp {inherit config osConfig lib pkgs userInfo;};
      lsp-format.enable = true;
      lspkind = import ./lspkind.nix;
      lualine = import ./lualine.nix;
      luasnip = import ./luasnip.nix pkgs;
      markdown-preview = import ./markdown-preview.nix;
      neocord = import ./neocord.nix config;
      noice.enable = true;
      none-ls = import ./none-ls.nix;
      oil = import ./oil.nix;
      otter.enable = true;
      rustaceanvim = import ./rustaceanvim.nix {inherit lib config pkgs;};
      sleuth.enable = true;
      treesitter = import ./treesitter.nix pkgs;
      trouble.enable = true;
      typescript-tools.enable = true;
      undotree.enable = true;
      web-devicons.enable = true;
      which-key = import ./which-key.nix;
    };

    extraPlugins = with pkgs.vimPlugins; [
      cellular-automaton-nvim
      vim-be-good
    ];
  };
}
