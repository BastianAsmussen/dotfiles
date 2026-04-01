{
  flake.nixosModules.kanata = {
    services.kanata = {
      enable = true;

      keyboards.default = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          ;; Danish Colemak-DH layout with bilateral home-row mods.
          ;; Mirrors the Glove80 Glorious Engrammer configuration so that
          ;; Delta's built-in keyboard behaves identically to the external
          ;; split keyboard.
          ;;
          ;; The defsrc assumes a standard ANSI physical layout. Because XKB
          ;; (set to "dk" in niri) applies *after* kanata's output, the
          ;; Danish-specific keys (æ/ø/å at ;/' /[ positions) remain intact.
          ;;
          ;; Home-row mods use tap-preferred with 200ms tapping term to
          ;; match the Glove80 difficulty-level-4 timing. Bilateral
          ;; enforcement is not available in kanata, so care was taken to
          ;; mirror the Glove80's GACS (GUI-Alt-Ctrl-Shift) order.
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

          (defalias
            ;; Left-hand home-row mods (GACS order, matching Glove80).
            a_g (tap-hold 200 150 a lmet)   ;; tap a, hold GUI
            r_a (tap-hold 200 150 r lalt)   ;; tap r, hold Alt
            s_c (tap-hold 200 150 s lctl)   ;; tap s, hold Ctrl
            t_s (tap-hold 200 150 t lsft)   ;; tap t, hold Shift

            ;; Right-hand home-row mods (mirrored GACS).
            n_s (tap-hold 200 150 n rsft)   ;; tap n, hold Shift
            e_c (tap-hold 200 150 e rctl)   ;; tap e, hold Ctrl
            i_a (tap-hold 200 150 i lalt)   ;; tap i, hold Alt
            o_g (tap-hold 200 150 o rmet)   ;; tap o, hold GUI
          )
        '';
      };
    };
  };
}
