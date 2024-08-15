{pkgs, ...}: {
  programs.nixvim.plugins = {
    lsp = {
      enable = true;

      servers = {
        nil-ls = {
          enable = true;

          settings = {
            formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
            nix.binary = "/run/current-system/sw/bin/nix";
          };
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
    none-ls.enable = true;
  };
}
