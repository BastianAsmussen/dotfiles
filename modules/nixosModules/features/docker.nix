{
  flake.nixosModules.docker = {config, ...}: {
    virtualisation.docker = {
      enable = true;

      storageDriver = "btrfs";
      autoPrune.enable = true;
    };

    users.extraGroups.docker.members = [config.preferences.user.name];
  };
}
