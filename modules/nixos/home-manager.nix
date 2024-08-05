{
  inputs,
  config,
  lib,
  ...
}: let
  nixosOptions = config;
  hmOptions = config.home-manager;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager = with lib; {
    enable = mkEnableOption "Enables Home Manager.";
    username = mkOption {
      default = "bastian";
      description = "The username of the user.";
      type = types.str;
    };
  };

  config = lib.mkIf hmOptions.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs nixosOptions hmOptions;};

      useGlobalPkgs = true;
      useUserPackages = true;

      backupFileExtension = "backup";

      users."${hmOptions.username}" = import ../home-manager;
    };
  };
}
