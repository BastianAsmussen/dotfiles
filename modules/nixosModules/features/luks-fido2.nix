{
  flake.nixosModules.luksFido2 = {
    # The default script-based initrd does not include the systemd-cryptenroll
    # FIDO2 token handling required by `fido2-device=auto` in crypttabExtraOpts.
    # Switching to the systemd-based initrd pulls in systemd-cryptsetup which
    # knows how to talk to FIDO2 tokens (via libfido2) at boot.
    boot.initrd = {
      systemd.enable = true;

      # dm-crypt must be loaded in the initrd so the LUKS volume can be
      # opened before the root filesystem is mounted.
      kernelModules = ["dm-crypt"];

      # Ensure USB storage drivers are available in case the FIDO2 token
      # is on a USB bus that the default module set does not cover.
      availableKernelModules = ["usb_storage" "uas"];
    };
  };
}
