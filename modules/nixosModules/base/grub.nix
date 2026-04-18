{
  flake.nixosModules.grub = {
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      grub = {
        efiSupport = true;
        useOSProber = true;
        device = "nodev";
      };
    };

    stylix.targets.grub.useWallpaper = true;
  };
}
