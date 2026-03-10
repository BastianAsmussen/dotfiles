{lib}: let
  inherit (lib.custom.math) abs max;

  helpers = {
    # Helper for comparing floating point numbers with small margin of error.
    isClose = {
      margins ? {
        abs = 1.0e-6;
        rel = 1.0e-6;
      },
    }: a: b: let
      absDiff = abs (a - b);
      scale = max 1.0 (max (abs a) (abs b));
    in
      absDiff <= margins.abs || (absDiff / scale) <= margins.rel;

    # Helper to assert a generated float is between 0 and 1.
    inRange = value: value >= 0.0 && value <= 1.0;
  };

  base = import ./base.nix {inherit lib;};
  crypto = import ./crypto.nix {inherit lib;};
  random = import ./random.nix {inherit lib helpers;};
  trigenometry = import ./trigenometry.nix {inherit lib helpers;};
in
  base // crypto // random // trigenometry
