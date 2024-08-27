{
  inputs,
  config,
  lib,
  userInfo,
  ...
}: let
  osOptions = config;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager.enable = lib.mkEnableOption "Enables the `Home Manager` module.";

  config = lib.mkIf config.home-manager.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs osOptions userInfo;};

      useGlobalPkgs = true;
      useUserPackages = true;

      backupFileExtension = "backup";

      users."${userInfo.username}" = import ../home-manager;
    };
  };
}
