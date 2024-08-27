{
  lib,
  config,
  userInfo,
  ...
}: {
  options.docker = {
    enable = lib.mkEnableOption "Enables Docker support.";

    storageDriver = lib.mkOption {
      default = "btrfs";
      description = "The filesystem that Docker will use.";
    };
  };

  config = lib.mkIf config.docker.enable {
    virtualisation.docker = {
      enable = true;
      inherit (config.docker) storageDriver;

      autoPrune.enable = true;
    };

    users.extraGroups.docker.members = [userInfo.username];
  };
}
