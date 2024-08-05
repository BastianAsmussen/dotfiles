{
  lib,
  config,
  ...
}: let
  cfg = config.bootloader;
in {
  options.bootloader.isMultiboot = with lib;
    mkOption {
      default = false;
      description = "Use OS Prober.";
      type = types.bool;
    };

  config = {
    boot.loader = {
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
  };
}
