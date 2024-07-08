{
  programs.nixvim.plugins = {
    luasnip.enable = true;

    lspkind = {
      enable = true;
      cmp.enable = true;
    };

    cmp.enable = true;
  };
}
