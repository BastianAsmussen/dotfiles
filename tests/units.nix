{lib}: let
  inherit (lib.custom.units) mibToBytes;
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
}
