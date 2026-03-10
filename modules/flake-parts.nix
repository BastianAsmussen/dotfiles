{inputs, ...}: {
  imports = [
    inputs.disko.flakeModules.default
    inputs.home-manager.flakeModules.home-manager
  ];
}
