{lib}: let
  inherit (lib.custom.math) mod pow;
in {
  # Modulo Tests.
  testMod = {
    expr = mod 10 2;
    expected = 0;
  };

  testModWithNegative = {
    expr = mod (-10) 3;
    expected = -1;
  };

  testModWithLargeNumbers = {
    expr = mod 1000000 7;
    expected = 1;
  };

  # Exponentiation Tests.
  testPowWithExp0 = {
    expr = pow 2 0;
    expected = 1;
  };

  testPowWithExp1 = {
    expr = pow 5 1;
    expected = 5;
  };

  testPowWithExp2 = {
    expr = pow 3 2;
    expected = 9;
  };

  testPowWithNegativeBase = {
    expr = pow (-2) 3;
    expected = -8;
  };

  testPowWithLargeExp = {
    expr = pow 2 10;
    expected = 1024;
  };

  testPowWith1AsBase = {
    expr = pow 1 1000;
    expected = 1;
  };

  testPowWith0AsBase = {
    expr = pow 0 5;
    expected = 0;
  };
}
