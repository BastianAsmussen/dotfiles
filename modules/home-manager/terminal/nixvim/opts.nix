{pkgs, ...}: {
  programs.nixvim.opts = {
    number = true;
    relativenumber = true;
    showmode = false;

    undofile = true;
    backup = false;
    swapfile = false;

    ignorecase = true;
    smartcase = true;
    inccommand = "split";

    tabstop = 4;
    softtabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    smartindent = true;
    wrap = false;
    scrolloff = 8; # Number of lines to show around the cursor.

    signcolumn = "yes";
    list = true;
    listchars = {
      tab = "» ";
      trail = "·";
      nbsp = "␣";
    };

    termguicolors = pkgs.stdenv.isLinux;

    updatetime = 50; # Faster completion.
    colorcolumn = "80";
  };
}
