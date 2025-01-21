{lib}: let
  inherit (lib.custom.math) isPrime;
in {
  testPrimality1 = {
    expr = isPrime 1;
    expected = false;
  };

  testPrimality2 = {
    expr = isPrime 2;
    expected = true;
  };

  testPrimality3 = {
    expr = isPrime 3;
    expected = true;
  };

  testPrimality4 = {
    expr = isPrime 4;
    expected = false;
  };

  testPrimality5 = {
    expr = isPrime 5;
    expected = true;
  };

  testPrimality6 = {
    expr = isPrime 6;
    expected = false;
  };

  testPrimality7 = {
    expr = isPrime 7;
    expected = true;
  };

  testPrimality8 = {
    expr = isPrime 8;
    expected = false;
  };

  testPrimality9 = {
    expr = isPrime 9;
    expected = false;
  };

  testPrimality10 = {
    expr = isPrime 10;
    expected = false;
  };
}
