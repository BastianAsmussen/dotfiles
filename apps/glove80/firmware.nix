{
  inputs,
  pkgs,
}: let
  firmware = import inputs.glove80-zmk {inherit pkgs;};
  keymap = ./config/glove80.keymap;

  mkBoard = board:
    firmware.zmk.override {
      inherit keymap board;
    };

  left = mkBoard "glove80_lh";
  right = mkBoard "glove80_rh";
in
  firmware.combine_uf2 left right "glove80"
