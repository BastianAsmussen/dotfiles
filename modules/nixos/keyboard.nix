{
  config,
  lib,
  ...
}: let
  cfg = config.keyboard;
in {
  options.keyboard = {
    enable = lib.mkEnableOption "Enables custom keyboard mappings.";
    keyboards = lib.mkOption {
      default = [];
      description = ''
        The keyboards to apply the macros to.

        An empty list lets Kanata detect which input devices are keyboards and intercept them all.
      '';
      type = lib.types.listOf lib.types.str;
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
          (defalias esc-ctrl (tap-hold 150 150 esc lctl))
          (deflayer base @esc-ctrl)
        '';
      };
    };
  };
}
