{
  flake.diskoConfigurations.hostEpsilon = {
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
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
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

        extra = {
          type = "disk";
          device = "/dev/nvme1n1";
          content = {
            type = "gpt";
            partitions = {
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "extra_lvm";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
                  };

                  content = {
                    type = "lvm_pv";
                    vg = "extra";
                  };
                };
              };
            };
          };
        };

        backup = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions.root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/run/media/bastian/Backup";
                mountOptions = ["nofail"];
              };
            };
          };
        };
      };

      lvm_vg.extra = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              mountpoint = "/srv/media";
              mountOptions = [
                "compress=zstd:3"
                "noatime"
                "ssd"
                "discard=async"
                "space_cache=v2"
                "nofail"
              ];
            };
          };
        };
      };

      lvm_vg.nix = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "66G";
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
  };
}
