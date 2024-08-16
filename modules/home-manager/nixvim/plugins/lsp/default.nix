{
  imports = [
    ./none-ls.nix
    ./otter.nix
    ./rustaceanvim.nix
  ];

  programs.nixvim = {
    plugins = {
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

      nix.enable = true;
      lsp-format.enable = true;
      trouble.enable = true;
    };
  };
}
