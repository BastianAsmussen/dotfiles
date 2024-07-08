{inputs, ...}: {
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
      shiftwidth = 4;

      updatetime = 100; # Faster completion.
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    luaLoader.enable = true;
  };
}
