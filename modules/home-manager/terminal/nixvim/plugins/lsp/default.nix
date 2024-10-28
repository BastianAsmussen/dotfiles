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
          nixd = {
            enable = true;

            settings = {
              nixpkgs.expr =
                # nix
                ''
                  import <nixpkgs> {}
                '';
              formatting.command = ["${lib.getExe pkgs.alejandra}"];
              options = let
                flakeRoot = "/home/${userInfo.username}/dotfiles";
              in {
                nixos.expr =
                  # nix
                  ''
                    (builtins.getFlake ${flakeRoot}).nixosConfigurations.${osConfig.networking.hostName}.options
                  '';
              };
            };
          };

          clangd.enable = true;
          gopls.enable = true;
          omnisharp.enable = true;
          java_language_server.enable = true;
          pyright.enable = true;
          hls = {
            enable = true;
            installGhc = true;
          };

          svelte.enable = true;
          ts_ls.enable = true;
          html.enable = true;
          cssls.enable = true;
          typos_lsp = {
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
