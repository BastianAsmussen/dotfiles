{
  lib,
  config,
  userInfo,
  ...
}: {
  options.docker.enable = lib.mkEnableOption "Enables Docker support.";

  config = lib.mkIf config.docker.enable {
    virtualisation.docker = {
      enable = true;

      storageDriver = "btrfs";
      autoPrune.enable = true;
    };

    users.extraGroups.docker.members = [userInfo.username];
  };
}
