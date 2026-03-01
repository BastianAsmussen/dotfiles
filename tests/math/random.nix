{
  lib,
  helpers,
}: let
  inherit (lib.custom.math) pow mkRandom floor;
  inherit (helpers) isClose inRange;

  # Some utility constants and functions.
  WORD_SIZE = 64;
  MAX_WORD = (pow 2 WORD_SIZE) - 1;

  # Create some RNG instances for testing different initial seeds.
  rngDefault = mkRandom {}; # Uses the generateSeed logic.
  rngPosSeed = mkRandom {seed = 12345;};
  rngNegSeed = mkRandom {seed = -12345;};
  rngMaxSeed = mkRandom {seed = MAX_WORD;};
in {
  # Check random outputs for default seed are between 0 and 1.
  testDefaultRange = {
    expr = let
      result = rngDefault.random rngDefault.initialSeed;
    in
      inRange result.value;
    expected = true;
  };

  # Check random outputs for a positive seed are between 0 and 1.
  testPositiveSeedRange = {
    expr = let
      result = rngPosSeed.random rngPosSeed.initialSeed;
    in
      inRange result.value;
    expected = true;
  };

  # Check random outputs for a negative seed are between 0 and 1.
  testNegativeSeedRange = {
    expr = let
      # Use parentheses for negative arguments to avoid parsing issues:
      result = rngNegSeed.random rngNegSeed.initialSeed;
    in
      inRange result.value;
    expected = true;
  };

  # Check random outputs for the maximum seed are between 0 and 1.
  testMaxSeedRange = {
    expr = let
      result = rngMaxSeed.random rngMaxSeed.initialSeed;
    in
      inRange result.value;
    expected = true;
  };

  # Verify deterministic output, i.e. same seed gives same value every time.
  # Use parentheses for negative seeds to clarify the call.
  testDeterministicPositiveSeed = {
    expr = let
      r1 = rngPosSeed.random rngPosSeed.initialSeed;
      r2 = (mkRandom {seed = 12345;}).random 12345;
    in
      isClose {} r1.value r2.value;
    expected = true;
  };

  testDeterministicNegativeSeed = {
    expr = let
      r1 = rngNegSeed.random rngNegSeed.initialSeed;
      r2 = (mkRandom {seed = -12345;}).random (-12345);
    in
      isClose {} r1.value r2.value;
    expected = true;
  };

  testDeterministicMaxSeed = {
    expr = let
      r1 = rngMaxSeed.random rngMaxSeed.initialSeed;
      r2 = (mkRandom {seed = MAX_WORD;}).random MAX_WORD;
    in
      isClose {} r1.value r2.value;
    expected = true;
  };

  # Test randomInt with default seed, ensuring it's within given bounds.
  testRandomIntDefault = let
    min = 5;
    max = 10;
    rInt = rngDefault.randomInt {
      seed = rngDefault.initialSeed;
      inherit min max;
    };
  in {
    expr =
      rInt.value
      >= min
      && rInt.value <= max
      && (rInt.value == floor rInt.value);
    expected = true;
  };

  # Test randomInt with negative seed, ensuring it's within given bounds.
  testRandomIntNegative = let
    min = 0;
    max = 5;
    rInt = rngNegSeed.randomInt {
      seed = rngNegSeed.initialSeed;
      inherit min max;
    };
  in {
    expr =
      rInt.value
      >= min
      && rInt.value <= max
      && (rInt.value == floor rInt.value);
    expected = true;
  };

  # Test randomInt with maximum seed, ensuring it's within given bounds.
  testRandomIntMaxSeed = let
    min = 100;
    max = 200;
    rInt = rngMaxSeed.randomInt {
      seed = rngMaxSeed.initialSeed;
      inherit min max;
    };
  in {
    expr =
      rInt.value
      >= min
      && rInt.value <= max
      && (rInt.value == floor rInt.value);
    expected = true;
  };

  # Check that generating multiple random values in sequence changes the seed.
  testSeedChange = {
    expr = let
      first = rngPosSeed.random rngPosSeed.initialSeed;
      second = rngPosSeed.random first.nextSeed;
    in
      first.nextSeed != second.nextSeed;
    expected = true;
  };

  # Simple sanity check that consecutive outputs are not identical.
  testNonTrivialOutput = {
    expr = let
      r1 = rngPosSeed.random 12345;
      r2 = rngPosSeed.random r1.nextSeed;
    in
      r1.value != r2.value;
    expected = true;
  };
}
