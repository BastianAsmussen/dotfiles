{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./plugins
    ./remaps.nix

    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    opts = {
      number = true;
      relativenumber = true;

      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;

      smartindent = true;

      wrap = false;

      swapfile = false;
      backup = false;
      undofile = true;

      hlsearch = false;
      incsearch = true;

      termguicolors = pkgs.stdenv.isLinux;

      scrolloff = 8; # Number of lines to show around the cursor.

      updatetime = 50; # Faster completion.
      colorcolumn = "80";
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    performance.byteCompileLua.enable = true;
    luaLoader.enable = true;
  };
}
