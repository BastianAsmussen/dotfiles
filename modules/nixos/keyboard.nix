{
  config,
  lib,
  ...
}: {
  options.keyboard.enable = lib.mkEnableOption "Enables custom keyboard mappings.";

  config = lib.mkIf config.keyboard.enable {
    services.kanata = {
      enable = true;

      keyboards.internalKeyboard = {
        extraDefCfg = "process-unmapped-keys yes";
        config =
          # lisp
          ''
            (defsrc caps)
            (defvar
              tap-time  150
              hold-time 200
            )

            (defalias caps (tap-hold-release $tap-time $hold-time esc lctl))
            (deflayer base @caps)
          '';
      };
    };
  };
}
