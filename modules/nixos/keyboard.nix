{
  config,
  lib,
  ...
}: let
  cfg = config.keyboard;
in {
  options.keyboard = with lib; {
    enable = mkEnableOption "Enables custom keyboard mappings.";
    keyboards = mkOption {
      default = [];
      description = ''
        The keyboards to apply the macros to.

        An empty list lets Kanata detect which input devices are keyboards and intercept them all.
      '';
      type = with types; listOf str;
    };
  };

  config = lib.mkIf cfg.enable {
    services.kanata = {
      enable = true;

      keyboards.internalKeyboard = {
        devices = cfg.keyboards;
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
