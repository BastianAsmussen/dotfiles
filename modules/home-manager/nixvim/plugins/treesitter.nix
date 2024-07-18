{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      settings = {
        auto_install = true;
        indent.enable = true;

        highlight.enable = true;
      };
    };

    hmts.enable = true;
  };
}
