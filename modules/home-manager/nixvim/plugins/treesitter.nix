{pkgs, ...}: {
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      settings = {
        auto_install = true;
        highlight.enable = true;
      };

      nixvimInjections = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
    };

    hmts.enable = true;
  };
}
