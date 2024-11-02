{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.hp-notebook-14-df0023
    ./hardware-configuration.nix
    (import ../../modules/nixos/disko.nix {device = "/dev/nvme0n1";})
  ];

  desktop = {
    audio.pipewire.enable = true;
    environment.hyprland.enable = true;
    greeter.gdm.enable = true;
  };

  bluetooth.enable = true;
}
