{inputs, ...}: {
  flake.nixosModules.hostDelta = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-pc
      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-pc-ssd
    ];

    services.thermald.enable = lib.mkDefault true;
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl
      ];
    };

    hardware.acpilight.enable = true;
    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  };
}
