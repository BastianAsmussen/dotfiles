{lib}: let
  inherit (lib.custom.math) abs max;

  helpers = {
    # Helper for comparing floating point numbers with small margin of error.
    isClose = a: b: let
      tol = 1.0e-4;
    in
      abs (a - b)
      < tol
      || abs (a - b) / max (abs a) (abs b) < tol;

    # Helper to assert a generated float is between 0 and 1.
    inRange = value: value >= 0.0 && value <= 1.0;
  };

  base = import ./base.nix {inherit lib;};
  crypto = import ./crypto.nix {inherit lib;};
  random = import ./random.nix {inherit lib helpers;};
  trigenometry = import ./trigenometry.nix {inherit lib helpers;};
in
  base // crypto // random // trigenometry
