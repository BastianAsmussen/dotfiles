{
  lib,
  config,
  ...
}: {
  options.audio.enable = lib.mkEnableOption "Enable audio drivers.";

  config = lib.mkIf config.audio.enable {
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
