{
  flake.nixosModules.grub = {
    lib,
    config,
    ...
  }: {
    options.grub.isMultiboot = lib.mkEnableOption "OS prober for dual-boot (e.g. Windows)";

    config = {
      boot.loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        grub = {
          efiSupport = true;
          useOSProber = config.grub.isMultiboot;
          device = "nodev";
          # Prevent kernel cmdline editing at boot (does not protect against evil-maid; use lanzaboote for that).
          extraConfig = ''set superusers=""'';
        };
      };

      stylix.targets.grub.useWallpaper = true;
    };
  };
}
