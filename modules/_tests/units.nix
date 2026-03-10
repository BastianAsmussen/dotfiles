{lib}: let
  inherit (lib.custom.units) mibToBytes toBinary;

  mkCases = cases:
    builtins.listToAttrs (map (
        c: {
          inherit (c) name;

          value = {
            inherit (c) expr expected;
          };
        }
      )
      cases);

  mibCases = [
    {
      name = "testMibToBytesConversion";
      expr = mibToBytes 256;
      expected = 268435456;
    }
    {
      name = "testZeroMib";
      expr = mibToBytes 0;
      expected = 0;
    }
    {
      name = "testNegativeMib";
      expr = mibToBytes (-1024);
      expected = -1073741824;
    }
  ];

  toBinaryCases = [
    {
      name = "testToBinaryZero";
      expr = toBinary 0;
      expected = [0];
    }
    {
      name = "testToBinaryOne";
      expr = toBinary 1;
      expected = [1];
    }
    {
      name = "testToBinaryTwo";
      expr = toBinary 2;
      expected = [1 0];
    }
    {
      name = "testToBinaryThree";
      expr = toBinary 3;
      expected = [1 1];
    }
    {
      name = "testToBinaryEight";
      expr = toBinary 8;
      expected = [1 0 0 0];
    }
    {
      name = "testToBinaryFifteen";
      expr = toBinary 15;
      expected = [1 1 1 1];
    }
    {
      name = "testToBinary42";
      expr = toBinary 42;
      expected = [1 0 1 0 1 0];
    }
  ];

  pow2Inputs = [1 2 4 8 16 32 64];
  pow2Cases =
    map (
      i: let
        idx = lib.lists.findFirstIndex (x: x == i) null pow2Inputs; # 0-based exponent.
        zerosCount =
          if idx == null
          then 0
          else idx;
        zeros = builtins.genList (_: 0) zerosCount;
        expected = [1] ++ zeros;
      in {
        inherit expected;

        name = "testToBinaryPowersOf2${toString i}";
        expr = toBinary i;
      }
    )
    pow2Inputs;
in
  mkCases (mibCases ++ toBinaryCases ++ pow2Cases)
