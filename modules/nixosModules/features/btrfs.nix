{
  flake.nixosModules.btrfs = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption types;

    cfg = config.btrfs;
  in {
    options.btrfs = {
      scrub = {
        interval = mkOption {
          default = "weekly";
          description = "How frequently to scrub the filesystem.";
          type = types.str;
        };

        fileSystems = mkOption {
          default = ["/"];
          description = "A list of the filesystems to scrub.";
          type = types.listOf types.str;
        };
      };
    };

    config = {
      services = {
        fstrim.enable = true;
        btrfs.autoScrub = {
          enable = true;

          inherit (cfg.scrub) interval fileSystems;
        };
      };
    };
  };
}
