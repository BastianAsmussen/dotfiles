pkgs: {
  enable = true;

  grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
  settings = {
    highlight = {
      enable = true;

      additional_vim_regex_highlighting = true;
    };

    indent.enable = true;
  };
}
