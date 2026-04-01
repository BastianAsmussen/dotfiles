{inputs, ...}: {
  flake.nixosModules.impermanence = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkIf mkAfter mkDefault mkOption mkEnableOption types;

    cfg = config.persistance;
  in {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    options.persistance = {
      enable = mkEnableOption "enable persistance";

      nukeRoot.enable = mkEnableOption "destroy /root on every boot";

      volumeGroup = mkOption {
        default = "nix";
        description = "LVM volume group name containing the btrfs root.";
        type = types.str;
      };

      directories = mkOption {
        default = [];
        description = "Extra system directories to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };

      files = mkOption {
        default = [];
        description = "Extra system files to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };

      data.directories = mkOption {
        default = [];
        description = "User data directories to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };

      data.files = mkOption {
        default = [];
        description = "User data files to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };

      cache.directories = mkOption {
        default = [];
        description = "User cache directories to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };

      cache.files = mkOption {
        default = [];
        description = "User cache files to persist.";
        type = types.listOf (types.either types.str types.attrs);
      };
    };

    config = mkIf cfg.enable {
      fileSystems."/persist".neededForBoot = true;

      programs.fuse.userAllowOther = true;
      boot.tmp.cleanOnBoot = mkDefault true;

      environment.persistence = {
        "/persist/userdata".users."${config.preferences.user.name}" = {
          inherit (cfg.data) directories files;
        };

        "/persist/usercache".users."${config.preferences.user.name}" = {
          inherit (cfg.cache) directories files;
        };

        "/persist/system" = {
          hideMounts = true;
          directories =
            [
              "/var/log"
              "/var/lib/bluetooth"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/etc/NetworkManager/system-connections"
            ]
            ++ cfg.directories;
          files =
            [
              "/etc/machine-id"
            ]
            ++ cfg.files;
        };
      };

      boot.initrd.postDeviceCommands =
        mkIf cfg.nukeRoot.enable
        (mkAfter ''
          mkdir /btrfs_tmp
          mount /dev/${cfg.volumeGroup}/root /btrfs_tmp
          if [[ -e /btrfs_tmp/root ]]; then
              mkdir -p /btrfs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              delete_subvolume_recursively "$i"
          done

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '');
    };
  };
}
