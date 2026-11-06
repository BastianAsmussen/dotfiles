{
  flake.nixosModules.grub =
    {
      lib,
      config,
      ...
    }:
    {
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
            # Disable kernel command-line editing at boot.
            extraConfig = ''set superusers=""'';
          };
        };

        stylix.targets.grub.useWallpaper = true;
      };
    };
}
