{
  flake.nixosModules.kanata = {
    lib,
    pkgs,
    ...
  }: {
    services.kanata = {
      enable = true;

      keyboards.default = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          ;; Colemak-DH with home-row mods.
          ;; Tap = letter, hold = modifier.
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
            esc  @a_m @r_a @s_c @t_s g    m    @n_s @e_c @i_a @o_m '    ret
            lsft x    c    d    v    z    k    h    ,    .    /    rsft
            lctl lmet lalt           spc            ralt rmet rctl
          )

          (defalias
            ;; Left-hand home-row mods.
            a_m (tap-hold 200 150 a lmet)
            r_a (tap-hold 200 150 r lalt)
            s_c (tap-hold 200 150 s lctl)
            t_s (tap-hold 200 150 t lsft)

            ;; Right-hand home-row mods (mirrored).
            n_s (tap-hold 200 150 n rsft)
            e_c (tap-hold 200 150 e rctl)
            i_a (tap-hold 200 150 i lalt)
            o_m (tap-hold 200 150 o rmet)
          )
        '';
      };
    };
  };
}
