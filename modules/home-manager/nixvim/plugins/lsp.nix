{
  programs.nixvim.plugins = {
    lsp = {
      enable = true;

      servers = {
        nixd.enable = true;

        typos-lsp = {
          enable = true;

          extraOptions.init_options.diagnosticSeverity = "Hint";
        };

        tsserver.enable = true;
        html.enable = true;
        cssls.enable = true;
        svelte.enable = true;

        gopls.enable = true;
        pyright.enable = true;
        clangd.enable = true;
      };
    };

    lsp-format.enable = true;
    none-ls = {
      enable = true;

      sources = {
        code_actions = {
          statix.enable = true;
        };

        diagnostics = {
          statix.enable = true;
          deadnix.enable = true;
        };

        formatting.alejandra.enable = true;
      };
    };

    trouble.enable = true;
  };
}
