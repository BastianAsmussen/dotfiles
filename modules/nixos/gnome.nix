{
  lib,
  config,
  ...
}: {
  imports = [
    ./audio.nix
    ./sddm.nix
  ];

  options.gnome.enable = lib.mkEnableOption "Enables Gnome.";

  config = lib.mkIf config.gnome.enable {
    audio.enable = true;
    hardware.pulseaudio.enable = false;

    sddm.enable = true;

    services.xserver.desktopManager.gnome.enable = true;
  };
}
