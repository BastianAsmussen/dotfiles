{
  flake.nixosModules.kanata = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption types;

    cfg = config.kanata;
    tap = toString cfg.tapTimeout;
    hold = toString cfg.holdTimeout;
    idle = toString cfg.idleTimeout;
  in {
    options.kanata = {
      tapTimeout = mkOption {
        type = types.int;
        default = 200;
        description = ''
          Tap portion of the tap-hold timeout (milliseconds).
          Applies to all home-row mod keys.
        '';
      };

      holdTimeout = mkOption {
        type = types.int;
        default = 200;
        description = ''
          Hold portion of the tap-hold timeout (milliseconds).
          Applies to all home-row mod keys.
        '';
      };

      idleTimeout = mkOption {
        type = types.int;
        default = 300;
        description = ''
          Keyboard idle timeout (milliseconds) after which the `typing`
          layer automatically reverts to `base` via on-idle-fakekey.
        '';
      };
    };

    config.services.kanata = {
      enable = true;
      keyboards.default = {
        extraDefCfg = "process-unmapped-keys yes";
        config =
          # lisp
          ''
            (defvar
              tap-timeout   ${tap}
              hold-timeout  ${hold}
              idle-timeout  ${idle}
            )

            (defsrc
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              caps a    s    d    f    g    h    j    k    l    ;    '    ret
              lsft lsgt z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lmet lalt           spc            ralt      rctl
            )

            ;;; Virtual key fired by on-idle-fakekey to revert to the base layer.
            (defvirtualkeys
              idle-revert (layer-switch base)
            )

            (defalias
              ;; Tap spc/ralt for their normal function; hold to enter symbols.
              sym     (tap-hold $tap-timeout $hold-timeout spc  (layer-toggle symbols))
              sym-alt (tap-hold $tap-timeout $hold-timeout ralt (layer-toggle symbols))

              idle-arm (on-idle-fakekey idle-revert tap $idle-timeout)

              typ-a (multi a (layer-switch typing) @idle-arm)
              typ-r (multi r (layer-switch typing) @idle-arm)
              typ-s (multi s (layer-switch typing) @idle-arm)
              typ-t (multi t (layer-switch typing) @idle-arm)
              typ-n (multi n (layer-switch typing) @idle-arm)
              typ-e (multi e (layer-switch typing) @idle-arm)
              typ-i (multi i (layer-switch typing) @idle-arm)
              typ-o (multi o (layer-switch typing) @idle-arm)

              a_g (tap-hold-release $tap-timeout $hold-timeout @typ-a lmet) ;; tap a, hold GUI
              r_a (tap-hold-release $tap-timeout $hold-timeout @typ-r lalt) ;; tap r, hold Alt
              s_c (tap-hold-release $tap-timeout $hold-timeout @typ-s lctl) ;; tap s, hold Ctrl
              t_s (tap-hold-release $tap-timeout $hold-timeout @typ-t lsft) ;; tap t, hold Shift

              n_s (tap-hold-release $tap-timeout $hold-timeout @typ-n rsft) ;; tap n, hold Shift
              e_c (tap-hold-release $tap-timeout $hold-timeout @typ-e rctl) ;; tap e, hold Ctrl
              i_a (tap-hold-release $tap-timeout $hold-timeout @typ-i lalt) ;; tap i, hold Alt
              o_g (tap-hold-release $tap-timeout $hold-timeout @typ-o rmet) ;; tap o, hold GUI

              lcurly  (macro RA-7)    ;; {  (AltGr+7)
              rcurly  (macro RA-0)    ;; }  (AltGr+0)
              lsquare (macro RA-8)    ;; [  (AltGr+8)
              rsquare (macro RA-9)    ;; ]  (AltGr+9)
              bsl     (macro RA-lsgt) ;; \  (AltGr+lsgt)

              at    (unicode @)
              hash  (unicode #)
              dol   (unicode $)
              caret (unicode ^)
              tilde (unicode ~)
              pipe  (unicode |)
              unds  (unicode _)
            )

            (deflayer base
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    f    p    b    j    l    u    y    ;    [    ]    \
              esc  @a_g @r_a @s_c @t_s g    m    @n_s @e_c @i_a @o_g '    ret
              lsft lsgt z    x    c    d    v    k    h    ,    .    /    rsft
              lctl lmet lalt           @sym           @sym-alt  rctl
            )

            (deflayer typing
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    f    p    b    j    l    u    y    ;    [    ]    \
              esc  a    r    s    t    g    m    n    e    i    o    '    ret
              lsft lsgt z    x    c    d    v    k    h    ,    .    /    rsft
              lctl lmet lalt           @sym           @sym-alt  rctl
            )

            (deflayer symbols
              _    _    _     _     _    _    _    _     _     _     _    _    _    _
              _    S-1  @at   @hash @dol S-5  _    home  pgup  pgdn  bspc end  @caret @tilde
              _    =    @lcurly  S-8   S-9  @rcurly  _   left  up    down  rght @pipe _
              _    _    @bsl     @lsquare @rsquare @unds _   _     _     _     _    _    _
              _    _    _              _              _         _
            )
          '';
      };
    };
  };
}
