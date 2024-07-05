{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager.enable = lib.mkEnableOption "Enables Home Manager.";

  config = lib.mkIf config.home-manager.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs;};

      users.bastian = import ../home-manager/home.nix;
    };
  };
}
