{
  inputs,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.neovim =
      (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;

        modules = [self.flakeModules.nvfConfig];
      }).neovim;
  };
}
