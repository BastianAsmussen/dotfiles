{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.home-manager = {
    enable = lib.mkEnableOption "Enables Home Manager.";
    username = lib.mkOption {
      default = "bastian";
      description = "The username of the user.";
    };
  };

  config = lib.mkIf config.home-manager.enable {
    home-manager = with config.home-manager; {
      extraSpecialArgs = {inherit inputs username;};

      users."${username}" = import ../home-manager/home.nix;
    };
  };
}
