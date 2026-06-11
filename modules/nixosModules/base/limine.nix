{
  flake.nixosModules.limine = {
    boot.loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };

      limine.enable = true;
    };
  };
}
