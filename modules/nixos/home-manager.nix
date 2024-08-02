{
  inputs,
  config,
  lib,
  ...
}: let
  nixosOptions = config;
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

  config = lib.mkIf config.home-manager.enable {
    home-manager = with config.home-manager; {
      extraSpecialArgs = {inherit inputs username nixosOptions;};

      useGlobalPkgs = true;
      useUserPackages = true;

      backupFileExtension = "backup";

      users."${username}" = import ../home-manager;
    };
  };
}
