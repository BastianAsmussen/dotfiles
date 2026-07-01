{ config, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (config.flake.lib.custom.net) isIPv4 isMac normMac;

      cases = {
        testIPv4Valid = {
          expr = isIPv4 "192.168.1.64";
          expected = true;
        };

        testIPv4Max = {
          expr = isIPv4 "255.255.255.255";
          expected = true;
        };

        testIPv4OctetTooBig = {
          expr = isIPv4 "192.168.1.999";
          expected = false;
        };

        testIPv4TooFewOctets = {
          expr = isIPv4 "1.2.3";
          expected = false;
        };

        testIPv4EmptyOctet = {
          expr = isIPv4 "1.2.3.";
          expected = false;
        };

        testMacLowerColon = {
          expr = isMac "c8:7f:54:66:ff:72";
          expected = true;
        };

        testMacUpperDash = {
          expr = isMac "C8-7F-54-66-FF-72";
          expected = true;
        };

        testMacInvalid = {
          expr = isMac "zz:11";
          expected = false;
        };

        testNormMac = {
          expr = normMac "C8-7F-54-66-FF-72";
          expected = "c8:7f:54:66:ff:72";
        };
      };

      results = lib.runTests cases;
    in
    {
      checks.tests-net =
        if results == [ ] then
          pkgs.runCommandLocal "tests-net-pass" { } "touch $out"
        else
          pkgs.runCommandLocal "tests-net-fail"
            {
              RESULTS = lib.concatStringsSep "\n" (
                map (r: ''
                  ${r.name}:
                    expected: ${lib.generators.toPretty { } r.expected}
                    got:      ${lib.generators.toPretty { } r.result}
                '') results
              );
            }
            ''
              printf "Failed Tests:\n\n%s\n" "$RESULTS" >&2
              exit 1
            '';
    };
}
