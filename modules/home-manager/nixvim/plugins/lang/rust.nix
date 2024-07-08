{
  programs.nixvim = {
    globals.rustfmt_autosave = 1; # Format on save.

    plugins = {
      rustaceanvim.enable = true;
      crates-nvim.enable = true;
    };
  };
}
