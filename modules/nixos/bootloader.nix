{
  lib,
  config,
  ...
}: {
  options.bootloader.isMultiboot = lib.mkOption {
    default = false;
    description = "Use OS Prober.";
    type = lib.types.bool;
  };

  config = {
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        efiSupport = true;
        useOSProber = config.bootloader.isMultiboot;

        device = "nodev";
      };
    };
  };
}
