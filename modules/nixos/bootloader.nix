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

    stylix.targets.grub.useImage = true;
  };
}
