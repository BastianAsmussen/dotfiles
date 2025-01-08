{
  inputs,
  config,
  lib,
  userInfo,
  self,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager.enable = mkEnableOption "Enables the `Home Manager` module.";

  config = mkIf config.home-manager.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs userInfo self;};
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      users.${userInfo.username} = import ../home-manager;
    };
  };
}
