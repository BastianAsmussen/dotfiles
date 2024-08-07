{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    (import ./disko-config.nix {inherit config;})
  ];

  gdm.enable = true;
  gnome.enable = true;

  pipewire.enable = true;
  hardware.pulseaudio.enable = false;

  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    openmoji-color
  ];
}
