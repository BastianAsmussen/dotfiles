{
  programs.nixvim.plugins.lsp = {
    enable = true;

    servers = {
      rust-analyzer = {
        enable = true;

        installCargo = true;
        installRustc = true;
      };

      nixd.enable = true;

      tsserver.enable = true;
      html.enable = true;
      cssls.enable = true;
      svelte.enable = true;

      gopls.enable = true;
      pyright.enable = true;
      clangd.enable = true;
    };
  };
}
