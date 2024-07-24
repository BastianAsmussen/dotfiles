{
  inputs,
  config,
  lib,
  ...
}: {
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
      extraSpecialArgs = {inherit inputs username;};

      useGlobalPkgs = true;
      useUserPackages = true;

      users."${username}" = import ../home-manager/home.nix;
    };
  };
}
