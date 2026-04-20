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
        # Prevent kernel cmdline editing at boot (does not protect against evil-maid; use lanzaboote for that).
        extraConfig = ''set superusers=""'';
      };
    };

    stylix.targets.grub.useWallpaper = true;
  };
}
