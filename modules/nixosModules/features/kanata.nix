{
  flake.nixosModules.kanata = {
    services.kanata = {
      enable = true;

      keyboards.default = {
        extraDefCfg = "process-unmapped-keys yes";
        config =
          # lisp
          ''
            ;; Danish Colemak-DH layout with home-row mods.
            ;; Mirrors the Glove80 Glorious Engrammer configuration so that
            ;; built-in keyboard behaves identically to the external split
            ;; keyboard.
            (defsrc
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
              caps a    s    d    f    g    h    j    k    l    ;    '    ret
              lsft z    x    c    v    b    n    m    ,    .    /    rsft
              lctl lmet lalt           spc            ralt rmet rctl
            )

            (deflayer colemak-dh
              grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
              tab  q    w    f    p    b    j    l    u    y    ;    [    ]    \
              esc  @a_g @r_a @s_c @t_s g    m    @n_s @e_c @i_a @o_g '    ret
              lsft x    c    d    v    z    k    h    ,    .    /    rsft
              lctl lmet lalt           spc            ralt rmet rctl
            )

            (defvar
              tap-timeout 200
              hold-timeout 150
            )

            (defalias
              ;; Left-hand home-row mods.
              a_g (tap-hold $tap-timeout $hold-timeout a lmet)   ;; tap a, hold GUI
              r_a (tap-hold $tap-timeout $hold-timeout r lalt)   ;; tap r, hold Alt
              s_c (tap-hold $tap-timeout $hold-timeout s lctl)   ;; tap s, hold Ctrl
              t_s (tap-hold $tap-timeout $hold-timeout t lsft)   ;; tap t, hold Shift

              ;; Right-hand home-row mods.
              n_s (tap-hold $tap-timeout $hold-timeout n rsft)   ;; tap n, hold Shift
              e_c (tap-hold $tap-timeout $hold-timeout e rctl)   ;; tap e, hold Ctrl
              i_a (tap-hold $tap-timeout $hold-timeout i lalt)   ;; tap i, hold Alt
              o_g (tap-hold $tap-timeout $hold-timeout o rmet)   ;; tap o, hold GUI
            )
          '';
      };
    };
  };
}
