{
  programs.nixvim = {
    performance = {
      byteCompileLua = {
        enable = true;

        nvimRuntime = true;
        plugins = true;
      };

      combinePlugins = {
        enable = true;

        standalonePlugins = [
          "nvim-treesitter"
          "hmts.nvim"
        ];
      };
    };

    luaLoader.enable = true;
  };
}
