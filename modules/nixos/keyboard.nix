{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;

  cfg = config.keyboard;
in {
  options.keyboard = {
    enable = mkEnableOption "Enables custom keyboard mappings.";
    keyboards = mkOption {
      default = [];
      description = ''
        The keyboards to apply the macros to.

        An empty list lets Kanata detect which input devices are keyboards and intercept them all.
      '';
      type = types.listOf types.str;
    };
  };

  config = mkIf cfg.enable {
    services.kanata = {
      enable = true;

      keyboards.internalKeyboard = {
        devices = cfg.keyboards;
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc caps)
          (defalias esc-ctrl (tap-hold 100 200 esc lctl))
          (deflayer base @esc-ctrl)
        '';
      };
    };
  };
}
