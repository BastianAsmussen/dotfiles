{
  flake.nixosModules.pipewire = {
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
    services.pulseaudio.enable = false;
  };
}
