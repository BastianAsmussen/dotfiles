{
  programs.nixvim = {
    globals.rustfmt_autosave = 1; # Format on save.

    plugins.crates-nvim.enable = true;
  };
}
