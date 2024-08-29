{
  lib,
  config,
  ...
}: {
  options.desktop.audio.pipewire.enable = lib.mkEnableOption "Enable PipeWire audio drivers.";

  config = lib.mkIf config.desktop.audio.pipewire.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };

      pulse.enable = true;
    };

    # Disable PulseAudio.
    hardware.pulseaudio.enable = false;
  };
}
