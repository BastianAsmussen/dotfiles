{
  flake.nixosModules.podman = {
    virtualisation.podman = {
      enable = true;

      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune.enable = true;
    };

    virtualisation.containers.storage.settings.storage = {
      driver = "overlay";
      graphRoot = "/var/lib/containers/storage";
    };
  };
}
