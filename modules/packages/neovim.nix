{
  perSystem = {
    inputs',
    pkgs,
    config,
    ...
  }: {
    packages = {
      neovim = inputs'.nixvim.legacyPackages.makeNixvimWithModule {
        module = import ../homeManagerModules/_nixvim-config.nix;
      };

      neovim-minimal = inputs'.nixvim.legacyPackages.makeNixvimWithModule {
        module = {lib, ...}: {
          imports = [(import ../homeManagerModules/_nixvim-config.nix)];
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
            treesitter.grammarPackages = lib.mkForce (with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
              go
              just
              markdown
              nix
              python
              rust
              bash
              toml
            ]);
          };
        };
      };
    };

    apps.neovim = {
      type = "app";
      program = "${config.packages.neovim}/bin/nvim";
    };
  };
}
