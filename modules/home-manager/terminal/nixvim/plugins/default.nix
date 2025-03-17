{
  config,
  osConfig,
  self,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./dap.nix
    ./nvim-autopairs.nix
  ];

  programs.nixvim = {
    plugins = {
      cmp = import ./cmp.nix;
      crates.enable = true;
      colorizer = import ./colorizer.nix;
      comment = import ./comment.nix;
      direnv.enable = true;
      fidget.enable = true;
      gitsigns = import ./gitsigns.nix config;
      harpoon = import ./harpoon.nix;
      indent-blankline.enable = true;
      lsp = import ./lsp {inherit osConfig self lib pkgs;};
      lsp-format.enable = true;
      lspkind = import ./lspkind.nix;
      lualine = import ./lualine.nix;
      luasnip = import ./luasnip.nix pkgs;
      markdown-preview = import ./markdown-preview.nix;
      neocord = import ./neocord.nix config;
      nix.enable = true;
      none-ls = import ./none-ls.nix;
      oil = import ./oil.nix;
      otter.enable = true;
      rustaceanvim = import ./rustaceanvim.nix {inherit lib config pkgs;};
      sleuth.enable = true;
      snacks = import ./snacks;
      telescope = import ./telescope.nix;
      tmux-navigator = import ./tmux-navigator.nix;
      treesitter = import ./treesitter.nix pkgs;
      treesitter-context = import ./treesitter-context.nix;
      trouble.enable = true;
      ts-context-commentstring.enable = true;
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
