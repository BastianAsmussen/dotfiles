{
  programs.nixvim.plugins.lspkind = {
    enable = true;

    cmp.enable = true;
    mode = "symbol_text";
    extraOptions = {
      maxwidth = 50;
      ellipsis_char = "...";
    };
  };
}
