{
  lib,
  config,
  ...
}: {
  options.pipewire.enable = lib.mkEnableOption "Enable PipeWire audio drivers.";

  config = lib.mkIf config.pipewire.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      pulse.enable = true;
    };
  };
}
