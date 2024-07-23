{
  config,
  lib,
  ...
}: {
  options.keyboard = {
    enable = lib.mkEnableOption "Enables custom keyboard mappings.";
    keyboards = lib.mkOption {
      default = [];
      description = ''
        The keyboards to apply the macros to.

        An empty list lets kanata detect which input devices are keyboards and intercept them all.
      '';
      type = with lib.types; listOf str;
    };
  };

  config = lib.mkIf config.keyboard.enable {
    services.kanata = {
      enable = true;

      keyboards.internalKeyboard = {
        devices = config.keyboard.keyboards;
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc caps)
          (defalias escctrl (tap-hold 100 150 esc lctl))
          (deflayer base @escctrl)
        '';
      };
    };
  };
}
