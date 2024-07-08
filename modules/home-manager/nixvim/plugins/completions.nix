{
  programs.nixvim.plugins = {
    luasnip.enable = true;
    cmp = {
      enable = true;
      autoEnableSources = true;
    };
  };
}
