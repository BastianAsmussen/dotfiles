{
  flake.nixosModules.ipfs = {config, ...}: {
    services.kubo.enable = true;

    users.users."${config.preferences.user.name}".extraGroups = [config.services.kubo.group];
  };
}
