{pkgs, ...}: {
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      nixvimInjections = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;

      settings.highlight.enable = true;
    };

    treesitter-context.enable = true;
    treesitter-refactor.enable = true;

    hmts.enable = true;
  };
}
