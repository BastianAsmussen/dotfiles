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
        config = ''
          (defsrc
            caps

            ;; Home-row modifiers.
            a s d f
            j k l ;
          )

          (defvar
            tap-time 200
            hold-time 150

            left-hand-keys (
              q w e r t
              a s d f g
              z x c v b
            )

            right-hand-keys (
              y u i o p
              h j k l ;
              n m , . /
            )
          )

          (deflayer base
            @caps

            ;; Home-row modifiers.
            @a @s @d @f
            @j @k @l @;
          )

          (deflayer no-mods
            @caps

            a s d f
            j k l ;
          )

          (deffakekeys to-base (layer-switch base))
          (defalias
            caps (tap-hold-release $tap-time $hold-time esc lctl)

            ;; Home-row modifiers.
            tap (multi
              (layer-switch no-mods) ;; On tap, switch to the no-mods layer so we can type faster.
              (on-idle-fakekey to-base tap 20) ;; If we stop typing for 20ms, then switch back to the base layer.
            )

            a (tap-hold-release-keys $tap-time $hold-time (multi a @tap) lmet $left-hand-keys)
            s (tap-hold-release-keys $tap-time $hold-time (multi s @tap) lalt $left-hand-keys)
            d (tap-hold-release-keys $tap-time $hold-time (multi d @tap) lctl $left-hand-keys)
            f (tap-hold-release-keys $tap-time $hold-time (multi f @tap) lsft $left-hand-keys)

            j (tap-hold-release-keys $tap-time $hold-time (multi j @tap) rsft $right-hand-keys)
            k (tap-hold-release-keys $tap-time $hold-time (multi k @tap) rctl $right-hand-keys)
            l (tap-hold-release-keys $tap-time $hold-time (multi l @tap) ralt $right-hand-keys)
            ; (tap-hold-release-keys $tap-time $hold-time (multi ; @tap) rmet $right-hand-keys)
          )
        '';
      };
    };
  };
}
