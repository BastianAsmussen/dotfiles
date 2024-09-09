{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  desktop = {
    audio.pipewire.enable = true;
    environment.hyprland.enable = true;
    greeter.gdm.enable = true;
  };
}
