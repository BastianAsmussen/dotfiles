{ config, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (config.flake.lib.custom.math)
        pow
        mkRandom
        floor
        abs
        max
        ;

      isClose =
        {
          margins ? {
            abs = 1.0e-6;
            rel = 1.0e-6;
          },
        }:
        a: b:
        let
          absDiff = abs (a - b);
          scale = max 1.0 (max (abs a) (abs b));
        in
        absDiff <= margins.abs || (absDiff / scale) <= margins.rel;

      inRange = value: value >= 0.0 && value <= 1.0;

      WORD_SIZE = 64;
      MAX_WORD = (pow 2 WORD_SIZE) - 1;

      rngDefault = mkRandom { };
      rngPosSeed = mkRandom { seed = 12345; };
      rngNegSeed = mkRandom { seed = -12345; };
      rngMaxSeed = mkRandom { seed = MAX_WORD; };

      cases = {
        testDefaultRange = {
          expr =
            let
              result = rngDefault.random rngDefault.initialSeed;
            in
            inRange result.value;
          expected = true;
        };

        testPositiveSeedRange = {
          expr =
            let
              result = rngPosSeed.random rngPosSeed.initialSeed;
            in
            inRange result.value;
          expected = true;
        };

        testNegativeSeedRange = {
          expr =
            let
              result = rngNegSeed.random rngNegSeed.initialSeed;
            in
            inRange result.value;
          expected = true;
        };

        testMaxSeedRange = {
          expr =
            let
              result = rngMaxSeed.random rngMaxSeed.initialSeed;
            in
            inRange result.value;
          expected = true;
        };

        testDeterministicPositiveSeed = {
          expr =
            let
              r1 = rngPosSeed.random rngPosSeed.initialSeed;
              r2 = (mkRandom { seed = 12345; }).random 12345;
            in
            isClose { } r1.value r2.value;
          expected = true;
        };

        testDeterministicNegativeSeed = {
          expr =
            let
              r1 = rngNegSeed.random rngNegSeed.initialSeed;
              r2 = (mkRandom { seed = -12345; }).random (-12345);
            in
            isClose { } r1.value r2.value;
          expected = true;
        };

        testDeterministicMaxSeed = {
          expr =
            let
              r1 = rngMaxSeed.random rngMaxSeed.initialSeed;
              r2 = (mkRandom { seed = MAX_WORD; }).random MAX_WORD;
            in
            isClose { } r1.value r2.value;
          expected = true;
        };

        testRandomIntDefault =
          let
            min = 5;
            max = 10;
            rInt = rngDefault.randomInt {
              seed = rngDefault.initialSeed;
              inherit min max;
            };
          in
          {
            expr = rInt.value >= min && rInt.value <= max && (rInt.value == floor rInt.value);
            expected = true;
          };

        testRandomIntNegative =
          let
            min = 0;
            max = 5;
            rInt = rngNegSeed.randomInt {
              seed = rngNegSeed.initialSeed;
              inherit min max;
            };
          in
          {
            expr = rInt.value >= min && rInt.value <= max && (rInt.value == floor rInt.value);
            expected = true;
          };

        testRandomIntMaxSeed =
          let
            min = 100;
            max = 200;
            rInt = rngMaxSeed.randomInt {
              seed = rngMaxSeed.initialSeed;
              inherit min max;
            };
          in
          {
            expr = rInt.value >= min && rInt.value <= max && (rInt.value == floor rInt.value);
            expected = true;
          };

        testSeedChange = {
          expr =
            let
              first = rngPosSeed.random rngPosSeed.initialSeed;
              second = rngPosSeed.random first.nextSeed;
            in
            first.nextSeed != second.nextSeed;
          expected = true;
        };

        testNonTrivialOutput = {
          expr =
            let
              r1 = rngPosSeed.random 12345;
              r2 = rngPosSeed.random r1.nextSeed;
            in
            r1.value != r2.value;
          expected = true;
        };
      };

      results = lib.runTests cases;
    in
    {
      checks.tests-math-random =
        if results == [ ] then
          pkgs.runCommandLocal "tests-math-random-pass" { } "touch $out"
        else
          pkgs.runCommandLocal "tests-math-random-fail"
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
