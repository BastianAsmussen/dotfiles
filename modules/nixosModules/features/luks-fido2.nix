{
  flake.nixosModules.luksFido2 = {
    boot.initrd = {
      kernelModules = [ "dm-crypt" ];
      availableKernelModules = [ "usbhid" ];
    };
  };
}
