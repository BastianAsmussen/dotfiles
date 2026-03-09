{
  flake.nixosModules.networkManager = {userInfo, ...}: {
    networking.networkmanager.enable = true;

    users.extraGroups.networkmanager.members = [userInfo.username];
  };
}
