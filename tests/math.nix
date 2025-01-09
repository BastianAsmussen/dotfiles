{lib}: let
  inherit (lib.custom.math) mod pow;
in {
  testMathMod = {
    expr = mod 10 2;
    expected = 0;
  };

  testMathPowWithExp0 = {
    expr = pow 2 0;
    expected = 1;
  };
}
