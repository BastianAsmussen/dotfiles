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

      keyboards = {
        internalKeyboard = {
          devices = config.keyboard.keyboards;
          config = ''
            (defsrc
              f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
              caps
            )

            ;; Definine two aliases, one for esc/control to other for function key.
            (defalias
              escctrl (tap-hold 100 100 esc lctl)
            )

            (deflayer base
              brdn  brup  _    _    _    _   prev  pp  next  mute  vold  volu
              @escctrl
            )

            (deflayer fn
              f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
              @escctrl
            )
          '';
        };
      };
    };
  };
}
