{
  flake.nixosModules.luksFido2 = {
    boot.initrd = {
      systemd.enable = true;
      kernelModules = ["dm-crypt"];
      availableKernelModules = ["usbhid"];
    };
  };
}
