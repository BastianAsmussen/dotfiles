{
  flake.nixosModules.podman = {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        autoPrune.enable = true;
      };

      containers.registries.settings.unqualified-search-registries = [
        "docker.io"
        "ghcr.io"
      ];
    };
  };
}
