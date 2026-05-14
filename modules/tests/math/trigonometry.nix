{ config, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (config.flake.lib.custom.math)
        sqrt
        pow
        sin
        cos
        tan
        TAU
        PI
        HALF_PI
        abs
        max
        ;

      mkIsClose =
        margins: a: b:
        let
          absDiff = abs (a - b);
          scale = max 1.0 (max (abs a) (abs b));
        in
        absDiff <= margins.abs || (absDiff / scale) <= margins.rel;

      isClose = mkIsClose {
        abs = 1.0e-6;
        rel = 1.0e-6;
      };

      tanIsClose = mkIsClose {
        abs = 1.0e-5;
        rel = 1.0e-5;
      };

      angle30 = PI / 6;
      angle45 = PI / 4;
      angle60 = PI / 3;
      angle90 = HALF_PI;
      angle180 = PI;
      angle270 = 3 * HALF_PI;
      angle360 = TAU;

      sqrt2 = sqrt 2;
      sqrt3 = sqrt 3;

      cases = {
        testSinZero = {
          expr = isClose (sin 0) 0.0;
          expected = true;
        };
        testSinHalfPi = {
          expr = isClose (sin angle90) 1.0;
          expected = true;
        };
        testSinPi = {
          expr = isClose (sin angle180) 0.0;
          expected = true;
        };
        testSin3HalfPi = {
          expr = isClose (sin angle270) (-1.0);
          expected = true;
        };
        testSinTau = {
          expr = isClose (sin angle360) 0.0;
          expected = true;
        };
        testSin30Deg = {
          expr = isClose (sin angle30) 0.5;
          expected = true;
        };
        testSin45Deg = {
          expr = isClose (sin angle45) (1 / sqrt2);
          expected = true;
        };
        testSin60Deg = {
          expr = isClose (sin angle60) (sqrt3 / 2);
          expected = true;
        };

        testCosZero = {
          expr = isClose (cos 0) 1.0;
          expected = true;
        };
        testCosHalfPi = {
          expr = isClose (cos angle90) 0.0;
          expected = true;
        };
        testCosPi = {
          expr = isClose (cos angle180) (-1.0);
          expected = true;
        };
        testCos3HalfPi = {
          expr = isClose (cos angle270) 0.0;
          expected = true;
        };
        testCosTau = {
          expr = isClose (cos angle360) 1.0;
          expected = true;
        };
        testCos30Deg = {
          expr = isClose (cos angle30) (sqrt3 / 2);
          expected = true;
        };
        testCos45Deg = {
          expr = isClose (cos angle45) (1 / sqrt2);
          expected = true;
        };
        testCos60Deg = {
          expr = isClose (cos angle60) 0.5;
          expected = true;
        };

        testTanZero = {
          expr = isClose (tan 0) 0.0;
          expected = true;
        };
        testTanHalfPi = {
          expr = (builtins.tryEval (tan angle90)).success;
          expected = false;
        };
        testTanPi = {
          expr = isClose (tan angle180) 0.0;
          expected = true;
        };
        testTan3HalfPi = {
          expr = (builtins.tryEval (tan angle270)).success;
          expected = false;
        };
        testTanTau = {
          expr = isClose (tan angle360) 0.0;
          expected = true;
        };
        testTan30Deg = {
          expr = tanIsClose (tan angle30) (1 / sqrt3);
          expected = true;
        };
        testTan45Deg = {
          expr = isClose (tan angle45) 1.0;
          expected = true;
        };
        testTan60Deg = {
          expr = tanIsClose (tan angle60) sqrt3;
          expected = true;
        };

        testPythagoreanIdentity = {
          expr = isClose ((pow (sin angle45) 2) + (pow (cos angle45) 2)) 1.0;
          expected = true;
        };

        testComplementaryAngles = {
          expr = isClose (sin angle30) (cos (angle90 - angle30));
          expected = true;
        };

        testSinNegativeAngle = {
          expr = isClose (sin (-angle30)) (-(sin angle30));
          expected = true;
        };

        testCosNegativeAngle = {
          expr = isClose (cos (-angle30)) (cos angle30);
          expected = true;
        };

        testSinPeriodicity = {
          expr = isClose (sin angle30) (sin (angle30 + angle360));
          expected = true;
        };

        testCosPeriodicity = {
          expr = isClose (cos angle45) (cos (angle45 + angle360));
          expected = true;
        };

        testSin60EqualsCos30 = {
          expr = isClose (sin angle60) (cos angle30);
          expected = true;
        };
      };

      results = lib.runTests cases;
    in
    {
      checks.tests-math-trigonometry =
        if results == [ ] then
          pkgs.runCommandLocal "tests-math-trigonometry-pass" { } "touch $out"
        else
          pkgs.runCommandLocal "tests-math-trigonometry-fail"
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
