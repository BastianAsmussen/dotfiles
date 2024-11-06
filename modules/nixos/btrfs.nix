{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;

  cfg = config.btrfs;
in {
  options.btrfs = {
    enable = mkEnableOption "Enables BTRFS services.";

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

  config = mkIf cfg.enable {
    services = {
      fstrim.enable = true;

      btrfs.autoScrub = {
        enable = true;

        inherit (cfg.scrub) interval fileSystems;
      };
    };
  };
}
