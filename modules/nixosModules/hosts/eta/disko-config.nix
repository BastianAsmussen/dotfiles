{
  flake.diskoConfigurations.hostEta = {
    disko.devices = {
      # tmpfs root, wiped every reboot. All state lives under /persist.
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=2G"
          "mode=755"
        ];
      };

      disk = {
        main = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "4G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };

              primary = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  # Consumed only during reprovision (disko format); supplied by
                  # the nixos-anywhere disk_encryption_key_scripts. Runtime boot
                  # still unlocks interactively over initrd SSH on port 2222.
                  passwordFile = "/tmp/disk-1.key";
                  settings.allowDiscards = true;
                  content = {
                    type = "lvm_pv";
                    vg = "main";
                  };
                };
              };
            };
          };
        };
      };

      lvm_vg.main = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "10G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };

          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };

                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };

                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
