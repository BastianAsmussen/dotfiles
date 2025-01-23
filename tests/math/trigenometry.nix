{
  lib,
  helpers,
}: let
  inherit (lib.custom.math) sqrt pow sin cos TAU PI HALF_PI;
  inherit (helpers) isClose;

  # Common angles for more readable tests.
  angle30 = PI / 6;
  angle45 = PI / 4;
  angle60 = PI / 3;
  angle90 = HALF_PI;
  angle180 = PI;
  angle360 = TAU;

  sqrt2 = sqrt 2;
  sqrt3 = sqrt 3;
in {
  # Critical angles.
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
    expr = isClose (sin (3 * angle90)) (-1.0);
    expected = true;
  };

  testSinTau = {
    expr = isClose (sin angle360) 0.0;
    expected = true;
  };

  # Common angles with exact values.
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

  # Cosine Tests.

  # Critical angles.
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
    expr = isClose (cos (3 * angle90)) 0.0;
    expected = true;
  };

  testCosTau = {
    expr = isClose (cos angle360) 1.0;
    expected = true;
  };

  # Common angles with exact values.
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

  # Trigenometric Identities.

  # Pythagorean identity: sin^2(a) + cos^2(a) = 1
  testPythagoreanIdentity = {
    expr = isClose ((pow (sin angle45) 2) + (pow (cos angle45) 2)) 1.0;
    expected = true;
  };

  # Complementary angles: sin(a) = cos(90deg - a)
  testComplementaryAngles = {
    expr = isClose (sin angle30) (cos (angle90 - angle30));
    expected = true;
  };

  # Negative angle identities.
  testSinNegativeAngle = {
    expr = isClose (sin (-angle30)) (-(sin angle30));
    expected = true;
  };

  testCosNegativeAngle = {
    expr = isClose (cos (-angle30)) (cos angle30);
    expected = true;
  };

  # Periodicity.
  testSinPeriodicity = {
    expr = isClose (sin angle30) (sin (angle30 + angle360));
    expected = true;
  };

  testCosPeriodicity = {
    expr = isClose (cos angle45) (cos (angle45 + angle360));
    expected = true;
  };

  # Special angle relationships.
  testSin60EqualsCos30 = {
    expr = isClose (sin angle60) (cos angle30);
    expected = true;
  };
}
