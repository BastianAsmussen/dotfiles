{ config, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (config.flake.lib.custom.math)
        isPrime
        rsaKeypair
        rsaEncrypt
        rsaDecrypt
        mod
        ;

      LIMIT = 100;

      primesUpTo =
        limit:
        let
          nums = lib.range 2 limit;
          sieve =
            list:
            if list == [ ] then
              [ ]
            else
              let
                p = builtins.head list;
                rest = builtins.tail list;
                filtered = builtins.filter (x: mod x p != 0) rest;
              in
              [ p ] ++ (sieve filtered);
        in
        sieve nums;

      knownPrimes = primesUpTo LIMIT;

      mkPrimeTests = builtins.listToAttrs (
        map
          (n: {
            name = "testIsPrime${toString n}";
            value = {
              expr = isPrime n;
              expected = builtins.elem n knownPrimes;
            };
          })
          (
            lib.range 0 LIMIT
            ++ [
              (-5)
              3.14
            ]
          )
      );

      mkRSATest =
        p: q: msg:
        let
          keys = rsaKeypair p q;
          cipher = rsaEncrypt msg keys.public;
        in
        {
          expr = rsaDecrypt cipher keys.private;
          expected = msg;
        };

      cases = mkPrimeTests // {
        testRSABasic = mkRSATest 61 53 42;
        testRSAZero = mkRSATest 61 53 0;
        testRSAMax = mkRSATest 61 53 (61 * 53 - 1);
        testRSADifferentPrimes = mkRSATest 47 43 42;

        testRSANonPrime = {
          expr = (builtins.tryEval (builtins.deepSeq (rsaKeypair 4 53) null)).success;
          expected = false;
        };
      };

      results = lib.runTests cases;
    in
    {
      checks.tests-math-crypto =
        if results == [ ] then
          pkgs.runCommandLocal "tests-math-crypto-pass" { } "touch $out"
        else
          pkgs.runCommandLocal "tests-math-crypto-fail"
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
