{
  programs.nixvim.plugins.lsp = {
    enable = true;

    servers = {
      rust-analyzer = {
        enable = true;

        # Provided by dev environments.
        installRustc = false;
        installCargo = false;
      };

      nixd.enable = true;

      tsserver.enable = true;
      html.enable = true;
      cssls.enable = true;
      svelte.enable = true;
    };
  };
}
