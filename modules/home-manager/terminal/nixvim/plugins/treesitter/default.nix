{pkgs, ...}: {
  imports = [
    ./context.nix
    ./refactor.nix
  ];

  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      nixvimInjections = true;
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;

      settings.highlight.enable = true;
    };

    hmts.enable = true;
  };
}
