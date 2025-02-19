{
  inputs,
  config,
  lib,
  pkgs,
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
      extraSpecialArgs = {inherit inputs pkgs userInfo self;};
      useUserPackages = true;
      backupFileExtension = "backup";
      users.${userInfo.username} = import ../home-manager;
    };
  };
}
