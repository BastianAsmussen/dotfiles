{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF02"; # For GRUB MBR.
            };

            ESP = {
              size = "4G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };

            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "luks_lvm";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];
                };

                content = {
                  type = "lvm_pv";
                  vg = "nix";
                };
              };
            };
          };
        };
      };
    };

    lvm_vg.nix = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "18G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };

        root = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd" "noatime"];
              };
            };
          };
        };
      };
    };
  };
}
