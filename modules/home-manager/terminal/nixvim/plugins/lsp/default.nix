{
  config,
  osConfig,
  lib,
  pkgs,
  userInfo,
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

        inlayHints = true;
        servers = {
          clangd.enable = true; # C/C++
          cssls.enable = true; # CSS
          dockerls = import ./dockerls.nix; # Docker
          gopls.enable = true; # Golang
          hls = import ./hls.nix; # Haskell
          html.enable = true; # HTML
          java_language_server.enable = true; # Java
          lua_ls = import ./lua_ls.nix;
          nixd = import ./nixd.nix {
            # Nix
            inherit osConfig config lib pkgs userInfo;
          };

          omnisharp = import ./omnisharp.nix; # C#
          pylsp.enable = true; # Python
          sqls.enable = true; # SQL
          svelte.enable = true; # Svelte
          ts_ls.enable = true; # TS/JS
          typos_lsp = import ./typos_lsp.nix;
        };
      };

      lsp-format.enable = true;
      lspsaga = import ./lspsaga.nix;
      nix.enable = true;
      none-ls = import ./none-ls.nix;
      otter.enable = true;
      ts-autotag.enable = true;
      trouble.enable = true;
    };
  };
}
