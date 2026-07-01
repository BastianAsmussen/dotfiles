{ lib, ... }:
let
  # Normalise a MAC to the canonical lowercase, colon-separated form.
  normMac = mac: lib.toLower (builtins.replaceStrings [ "-" ] [ ":" ] mac);
in
{
  # Small networking helpers for validating/normalising addresses in modules
  # (e.g. the router module's DHCP/NAT options). Unit-tested in modules/tests/net.
  customLib.net = {
    inherit normMac;

    # Whether a string is a 6-octet hex MAC (colon- or dash-separated).
    isMac = mac: builtins.match "[0-9a-f][0-9a-f](:[0-9a-f][0-9a-f]){5}" (normMac mac) != null;

    # Whether a string is a dotted-quad IPv4 address with octets in 0..255.
    isIPv4 =
      addr:
      let
        parts = lib.splitString "." addr;
      in
      builtins.length parts == 4
      && builtins.all (p: builtins.match "[0-9]+" p != null && lib.toInt p <= 255) parts;
  };
}
