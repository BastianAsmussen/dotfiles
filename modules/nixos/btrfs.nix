{
  lib,
  config,
  ...
}: let
  cfg = config.btrfs;
in {
  options.btrfs = with lib; {
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
        type = with types; listOf str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      fstrim.enable = true;

      btrfs.autoScrub = {
        enable = true;

        inherit (cfg.scrub) interval;
        inherit (cfg.scrub) fileSystems;
      };
    };
  };
}
