{
  flake.nixosModules.docker = {userInfo, ...}: {
    virtualisation.docker = {
      enable = true;

      storageDriver = "btrfs";
      autoPrune.enable = true;
    };

    users.extraGroups.docker.members = [userInfo.username];
  };
}
