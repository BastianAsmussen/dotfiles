{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;

  cfg = config.bootloader;
in {
  options.bootloader.isMultiboot = mkOption {
    default = false;
    description = "Use OS Prober.";
    type = types.bool;
  };

  config = {
    boot = {
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        grub = {
          efiSupport = true;
          useOSProber = cfg.isMultiboot;

          device = "nodev";
        };
      };

      initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state.";
        wantedBy = ["initrd.target"];
        before = ["sysroot.mount"]; # Mount the root filesystem before clearing.
        after = ["systemd-cryptsetup@enc.service"]; # Make sure it's done after encryption, i.e. LUKS/TPM process.
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir /btrfs_tmp
          mount /dev/nix/root /btrfs_tmp
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
        '';
      };
    };

    stylix.targets.grub.useImage = true;
  };
}
