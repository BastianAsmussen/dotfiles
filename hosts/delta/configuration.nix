{inputs, ...}: let
  hardware = inputs.nixos-hardware.nixosModules;
in {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./distributed-builds.nix

    hardware.common-cpu-intel
    hardware.common-gpu-intel
    hardware.common-pc-laptop
  ];

  desktop = {
    audio.pipewire.enable = true;
    environment.hyprland.enable = true;
    greeter.gdm.enable = true;
  };

  bluetooth.enable = true;
}
