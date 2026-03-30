{inputs, ...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    packages = {
      neovim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
        module = import ../homeManagerModules/_nixvim-config.nix;
      };

      neovim-minimal = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
        module = {lib, ...}: {
          imports = [(import ../homeManagerModules/_nixvim-config.nix)];
          plugins = {
            lsp.enable = lib.mkForce false;
            none-ls.enable = lib.mkForce false;
            rustaceanvim.enable = lib.mkForce false;
            lsp-format.enable = lib.mkForce false;
            lspkind.enable = lib.mkForce false;
            lsp-lines.enable = lib.mkForce false;
            typescript-tools.enable = lib.mkForce false;
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
