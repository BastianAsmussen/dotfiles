{inputs, ...}: {
  flake.nixosModules.impermanence = {
    lib,
    config,
    ...
  }: let
    cfg = config.persistance;
  in {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    options.persistance = {
      enable = lib.mkEnableOption "enable persistance";

      nukeRoot.enable = lib.mkEnableOption "destroy /root on every boot";

      volumeGroup = lib.mkOption {
        default = "nix";
        description = "LVM volume group name containing the btrfs root.";
        type = lib.types.str;
      };

      directories = lib.mkOption {
        default = [];
        description = "Extra system directories to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };

      files = lib.mkOption {
        default = [];
        description = "Extra system files to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };

      data.directories = lib.mkOption {
        default = [];
        description = "User data directories to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };

      data.files = lib.mkOption {
        default = [];
        description = "User data files to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };

      cache.directories = lib.mkOption {
        default = [];
        description = "User cache directories to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };

      cache.files = lib.mkOption {
        default = [];
        description = "User cache files to persist.";
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      };
    };

    config = lib.mkIf cfg.enable {
      fileSystems."/persist".neededForBoot = true;

      programs.fuse.userAllowOther = true;
      boot.tmp.cleanOnBoot = lib.mkDefault true;

      environment.persistence = {
        "/persist/userdata".users."${config.preferences.user.name}" = {
          directories = cfg.data.directories;
          files = cfg.data.files;
        };

        "/persist/usercache".users."${config.preferences.user.name}" = {
          directories = cfg.cache.directories;
          files = cfg.cache.files;
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
        lib.mkIf cfg.nukeRoot.enable
        (lib.mkAfter ''
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
