{
  programs.nixvim.plugins = {
    luasnip.enable = true;
    cmp.enable = true;
    lspkind = {
      enable = true;
      cmp.enable = true;
    };
    friendly-snippets.enable = true;
  };
}
