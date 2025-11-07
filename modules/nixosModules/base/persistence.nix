{
  flake.nixosModules.base = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkEnableOption mkOption;
  in {
    options.persistence = {
      enable = mkEnableOption "Enables persistence.";
      nukeRoot.enable = mkEnableOption "Destroy /root on every boot.";

      volumeGroup = mkOption {
        description = "Btrfs volume group name.";
        default = "btrfs_vg";
      };

      user = mkOption {
        description = "Primary user.";
        default = "${config.preferences.user.name}";
      };

      directories = mkOption {
        description = "Directories to persist.";
        default = [];
      };

      files = mkOption {
        description = "Files to persist.";
        default = [];
      };

      data.directories = mkOption {
        description = "Directories to persist.";
        default = [];
      };

      data.files = mkOption {
        description = "Files to persist.";
        default = [];
      };

      cache.directories = mkOption {
        description = "Directories to persist.";
        default = [];
      };

      cache.files = mkOption {
        description = "Files to persist.";
        default = [];
      };
    };
  };
}
