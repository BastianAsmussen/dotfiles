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
            grv   1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab   q    w    e    r    t    y    u    i    o    p    [    ]    ret
            caps  a    s    d    f    g    h    j    k    l    ;    '    \
            lsft lsgt  z    x    c    v    b    n    m    ,    .    /    rsft
            lctl lmet lalt            spc                 ralt rmet cmp  rctl
          )

          (defvar
            normal-tap-time 175
            ring-tap-time 200
            pinky-tap-time 250

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

          (defalias
            caps (tap-hold-release 200 $hold-time esc lctl)
            spc (tap-hold-release 200 $hold-time spc (layer-while-held nav))

            ;; Home-row modifiers.
            tap (multi
              (layer-switch no-mods) ;; On tap, switch to the no-mods layer so we can type faster.
              (on-idle-fakekey to-base tap 20) ;; If we stop typing for 20ms, then switch back to the base layer.
            )

            a (tap-hold-release-keys $pinky-tap-time $hold-time (multi a @tap) lmet $left-hand-keys)
            s (tap-hold-release-keys $ring-tap-time $hold-time (multi s @tap) lalt $left-hand-keys)
            d (tap-hold-release-keys $normal-tap-time $hold-time (multi d @tap) lsft $left-hand-keys)
            f (tap-hold-release-keys $normal-tap-time $hold-time (multi f @tap) lctl $left-hand-keys)

            j (tap-hold-release-keys $normal-tap-time $hold-time (multi j @tap) rctl $right-hand-keys)
            k (tap-hold-release-keys $normal-tap-time $hold-time (multi k @tap) rsft $right-hand-keys)
            l (tap-hold-release-keys $ring-tap-time $hold-time (multi l @tap) ralt $right-hand-keys)
            ; (tap-hold-release-keys $pinky-tap-time $hold-time (multi ; @tap) rmet $right-hand-keys)
          )

          (deflayer base
            grv   1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab   q    w    e    r    t    y    u    i    o    p    [    ]    ret
            @caps @a   @s   @d   @f   g    h    @j   @k   @l   @;   '    \
            XX   lsgt  z    x    c    v    b    n    m    ,    .    /    XX
            XX   XX   XX              @spc                XX   XX   cmp  XX
          )

          (deflayermap nav
            ___ XX

            caps @caps

            h left
            j down
            k up
            l right
          )

          (deflayermap no-mods
            ___ XX

            caps @caps
          )

          (deffakekeys to-base (layer-switch base))
        '';
      };
    };
  };
}
