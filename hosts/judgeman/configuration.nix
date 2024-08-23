{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  desktop = {
    greeter.gdm.enable = true;
    environment.gnome.enable = true;
  };

  pipewire.enable = true;
  hardware.pulseaudio.enable = false;

  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    openmoji-color
  ];
}
