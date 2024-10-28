{
  programs.nixvim = {
    performance.byteCompileLua = {
      enable = true;

      nvimRuntime = true;
      plugins = true;
    };

    luaLoader.enable = true;
  };
}
