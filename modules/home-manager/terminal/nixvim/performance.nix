{
  programs.nixvim = {
    luaLoader.enable = true;
    performance = {
      byteCompileLua = {
        enable = true;

        nvimRuntime = true;
        plugins = true;
      };

      combinePlugins = {
        enable = true;

        standalonePlugins = ["nvim-treesitter"];
      };
    };
  };
}
