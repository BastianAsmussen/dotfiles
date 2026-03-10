{inputs, ...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    packages.neovim = inputs.nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
      module = import ../homeManagerModules/_nixvim-config.nix;
    };

    apps.neovim = {
      type = "app";
      program = "${config.packages.neovim}/bin/nvim";
    };
  };
}
