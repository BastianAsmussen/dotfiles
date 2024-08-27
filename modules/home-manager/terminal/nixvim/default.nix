{inputs, ...}: {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim

    ./plugins
    ./keymaps.nix
    ./opts.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    performance.byteCompileLua.enable = true;
    luaLoader.enable = true;
  };
}
