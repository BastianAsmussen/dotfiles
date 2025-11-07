{inputs, self, ...}: {
  perSystem = {pkgs, config, ...}: {
    packages.neovim = (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;

      modules = [self.flakeModules.nvfConfig];
    }).neovim;
  };
}