{
  flake.nixosModules.host_lambda = {
    config,
    lib,
    modulesPath,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
      initrd = {
        availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "sd_mod"];
        kernelModules = ["dm-snapshot"];
      };

      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    networking.useDHCP = mkDefault true;

    nixpkgs.hostPlatform = mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  };
}
