{lib}: let
  inherit (lib.custom.units) mibToBytes;
in {
  testMibToBytesConversion = {
    expr = mibToBytes 256;
    expected = 268435456;
  };
}
