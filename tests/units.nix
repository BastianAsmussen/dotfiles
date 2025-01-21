{lib}: let
  inherit (lib.custom.units) mibToBytes toBinary;
in {
  testMibToBytesConversion = {
    expr = mibToBytes 256;
    expected = 268435456;
  };

  testZeroMib = {
    expr = mibToBytes 0;
    expected = 0;
  };

  testNegativeMib = {
    expr = mibToBytes (-1024);
    expected = -1073741824;
  };

  testToBinaryZero = {
    expr = toBinary 0;
    expected = [0];
  };

  testToBinaryOne = {
    expr = toBinary 1;
    expected = [1];
  };

  testToBinaryTwo = {
    expr = toBinary 2;
    expected = [1 0];
  };

  testToBinaryThree = {
    expr = toBinary 3;
    expected = [1 1];
  };

  testToBinaryEight = {
    expr = toBinary 8;
    expected = [1 0 0 0];
  };

  testToBinaryFifteen = {
    expr = toBinary 15;
    expected = [1 1 1 1];
  };

  testToBinary42 = {
    expr = toBinary 42;
    expected = [1 0 1 0 1 0];
  };

  testToBinaryPowersOf2 = {
    expr = [
      (toBinary 1) # 2^0
      (toBinary 2) # 2^1
      (toBinary 4) # 2^2
      (toBinary 8) # 2^3
      (toBinary 16) # 2^4
      (toBinary 32) # 2^5
      (toBinary 64) # 2^6
    ];
    expected = [
      [1]
      [1 0]
      [1 0 0]
      [1 0 0 0]
      [1 0 0 0 0]
      [1 0 0 0 0 0]
      [1 0 0 0 0 0 0]
    ];
  };
}
