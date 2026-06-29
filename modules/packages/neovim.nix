{
  perSystem =
    {
      inputs',
      pkgs,
      config,
      lib,
      ...
    }:
    {
      packages =
        let
          baseMeta = {
            license = lib.licenses.vim;
            maintainers = [ lib.maintainers.BastianAsmussen ];
            platforms = lib.platforms.linux;
            mainProgram = "nvim";
          };
        in
        {
          neovim =
            (inputs'.nixvim.legacyPackages.makeNixvimWithModule {
              module = {
                imports = [ (import ../homeManagerModules/_nixvim-config.nix) ];
                nixpkgs.pkgs = pkgs;
              };
            })
            // {
              meta = baseMeta // {
                description = "Bastian's full nixvim configuration (LSP, DAP, all language tooling).";
              };
            };

          neovim-minimal =
            (inputs'.nixvim.legacyPackages.makeNixvimWithModule {
              module =
                { lib, ... }:
                {
                  imports = [ (import ../homeManagerModules/_nixvim-config.nix) ];
                  nixpkgs.pkgs = pkgs;
                  plugins = {
                    # LSP.
                    lsp.enable = lib.mkForce false;
                    none-ls.enable = lib.mkForce false;
                    rustaceanvim.enable = lib.mkForce false;
                    lsp-format.enable = lib.mkForce false;
                    lspkind.enable = lib.mkForce false;
                    lsp-lines.enable = lib.mkForce false;
                    typescript-tools.enable = lib.mkForce false;

                    # DAP.
                    dap.enable = lib.mkForce false;
                    dap-ui.enable = lib.mkForce false;
                    dap-virtual-text.enable = lib.mkForce false;
                    cmp-dap.enable = lib.mkForce false;

                    # Miscellaneous heavy plugins.
                    crates.enable = lib.mkForce false;
                    markdown-preview.enable = lib.mkForce false;

                    # Use grammars used in the dotfiles (found with `tokei .`).
                    treesitter.grammarPackages = lib.mkForce (
                      with pkgs.vimPlugins.nvim-treesitter.builtGrammars;
                      [
                        go
                        just
                        markdown
                        nix
                        python
                        rust
                        bash
                        toml
                      ]
                    );
                  };
                };
            })
            // {
              meta = baseMeta // {
                description = "Minimal nixvim build: LSP, DAP, and heavy plugins disabled.";
              };
            };
        };

      apps.neovim = {
        type = "app";
        program = "${config.packages.neovim}/bin/nvim";
        meta.description = "Bastian's full nixvim configuration (LSP, DAP, all language tooling).";
      };
    };
}
