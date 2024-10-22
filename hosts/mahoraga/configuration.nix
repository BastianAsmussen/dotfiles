{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.hp-notebook-14-df0023
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  desktop = {
    audio.pipewire.enable = true;
    environment.hyprland.enable = true;
    greeter.gdm.enable = true;
  };

  bluetooth.enable = true;
}
