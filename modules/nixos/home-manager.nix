{
  inputs,
  config,
  lib,
  ...
}: let
  osOptions = config;
  hmOptions = config.home-manager;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager = {
    enable = lib.mkEnableOption "Enables Home Manager.";
    username = lib.mkOption {
      default = "bastian";
      description = "The username of the user.";
      type = lib.types.str;
    };
  };

  config = lib.mkIf hmOptions.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs osOptions hmOptions;};

      useGlobalPkgs = true;
      useUserPackages = true;

      backupFileExtension = "backup";

      users."${hmOptions.username}" = import ../home-manager;
    };
  };
}
