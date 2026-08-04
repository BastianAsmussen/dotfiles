{
  flake.nixosModules.time = { lib, config, ... }: {
    services = {
      timesyncd.enable = false;

      chrony = {
        enable = true;
        enableNTS = true;
      };
    };

    # Work around for https://github.com/NixOS/nixpkgs/issues/445035.
    systemd.tmpfiles.rules = lib.mkAfter [
      "z ${config.services.chrony.directory}/chrony.keys 0640 root chrony - -"
    ];
  };
}
