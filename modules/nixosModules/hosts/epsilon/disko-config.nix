{
  flake.diskoConfigurations.hostEpsilon = {
    disko.devices = {
      # tmpfs root, wiped every reboot. All state lives under /persist.
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = ["size=4G" "mode=755"];
      };

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

              swap = {
                size = "66G";
                content = {
                  type = "luks";
                  name = "swap_crypt";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
                  };

                  content = {
                    type = "swap";
                    resumeDevice = true;
                  };
                };
              };

              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "raid_p1";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
                  };
                };
              };
            };
          };
        };

        mirror = {
          type = "disk";
          device = "/dev/nvme1n1";
          content = {
            type = "gpt";
            partitions = {
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "raid_p2";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
                  };

                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-f"
                      "-d raid1"
                      "-m raid1"
                      "/dev/mapper/raid_p1"
                    ];

                    subvolumes = {
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = ["compress=zstd" "noatime" "ssd" "discard=async"];
                      };

                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = ["compress=zstd" "noatime" "ssd" "discard=async"];
                      };
                    };
                  };
                };
              };
            };
          };
        };

        media = {
          type = "disk";
          device = "/dev/sdb";
          content = {
            type = "gpt";
            partitions = {
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "media_crypt";
                  settings = {
                    crypttabExtraOpts = [
                      "fido2-device=auto"
                      "token-timeout=10"
                    ];
                  };

                  content = {
                    type = "btrfs";
                    extraArgs = ["-f"];
                    mountpoint = "/srv/media";
                    mountOptions = [
                      "compress=zstd:3"
                      "noatime"
                      "autodefrag"
                      "space_cache=v2"
                      "nofail"
                    ];
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
    };
  };
}
