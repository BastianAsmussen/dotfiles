{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  desktop = {
    audio.pipewire.enable = true;
    environment.gnome.enable = true;
    greeter.gdm.enable = true;
  };
}
