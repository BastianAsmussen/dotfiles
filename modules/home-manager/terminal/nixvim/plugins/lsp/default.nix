{
  lib,
  pkgs,
  userInfo,
  osConfig,
  ...
}: {
  imports = [
    ./cmp
    ./rustaceanvim.nix
  ];

  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;

        servers = {
          clangd.enable = true;
          cssls.enable = true;
          dockerls = import ./dockerls.nix;
          gopls.enable = true;
          hls = import ./hls.nix;
          html.enable = true;
          java_language_server.enable = true;
          nixd = import ./nixd.nix {inherit lib pkgs userInfo osConfig;};
          omnisharp = import ./omnisharp.nix;
          pylsp.enable = true;
          sqls.enable = true;
          svelte.enable = true;
          ts_ls.enable = true;
          typos_lsp = import ./typos_lsp.nix;
        };
      };

      lsp-format.enable = true;
      nix.enable = true;
      otter.enable = true;
      trouble.enable = true;
    };
  };
}
