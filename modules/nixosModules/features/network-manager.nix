{
  flake.nixosModules.networkManager = {config, ...}: {
    networking.networkmanager.enable = true;

    users.extraGroups.networkmanager.members = [config.preferences.user.name];
  };
}
