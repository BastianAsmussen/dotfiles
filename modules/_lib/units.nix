{lib}: let
  inherit (lib.custom.math) mod;
in {
  mibToBytes = mib: mib * 1024 * 1024;

  toBinary = n: let
    addBit = acc: n:
      if n == 0
      then acc
      else let
        bit = mod n 2;
        next = n / 2;
      in
        addBit ([bit] ++ acc) next;
  in
    if n == 0
    then [0]
    else addBit [] n;
}
