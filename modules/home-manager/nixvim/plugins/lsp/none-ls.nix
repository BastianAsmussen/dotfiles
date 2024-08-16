{
  programs.nixvim.plugins.none-ls = {
    enable = true;

    sources = {
      code_actions.statix.enable = true;

      diagnostics = {
        statix.enable = true;
        deadnix.enable = true;
      };

      formatting.alejandra.enable = true;
    };
  };
}
