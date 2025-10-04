{
  lib,
  config,
  userInfo,
  ...
}: {
  options.ipfs.enable = lib.mkEnableOption "Enables the InterPlanetary File System.";

  config = lib.mkIf config.ipfs.enable {
    services.kubo.enable = true;

    users.users.${userInfo.username}.extraGroups = [
      config.services.kubo.group
    ];
  };
}
