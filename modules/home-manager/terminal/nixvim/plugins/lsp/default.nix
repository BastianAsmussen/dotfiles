{
  imports = [
    ./cmp
    ./none-ls.nix
    ./rustaceanvim.nix
  ];

  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;

        servers = {
          nixd.enable = true;
          clangd.enable = true;
          gopls.enable = true;
          omnisharp.enable = true;
          java-language-server.enable = true;
          pyright.enable = true;
          hls.enable = true;
          svelte.enable = true;
          ts-ls.enable = true;
          html.enable = true;
          cssls.enable = true;
          typos-lsp = {
            enable = true;

            extraOptions.init_options.diagnosticSeverity = "Hint";
          };
        };
      };

      lsp-format.enable = true;
      trouble.enable = true;
      nix.enable = true;
      otter.enable = true;
    };
  };
}
