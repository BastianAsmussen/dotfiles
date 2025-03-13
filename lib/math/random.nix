{
  lib,
  base,
}: let
  inherit (base) mod pow floor;
  inherit (builtins) currentTime currentSystem nixVersion langVersion nixPath storeDir toJSON hashString toString;
  inherit (lib) stringToCharacters substring foldl;

  inPureMode = lib.trivial.inPureEvalMode;
  WORD_SIZE = 64;
  MAX_WORD = pow 2 WORD_SIZE - 1;

  # Generate a seed using system information if pure, or use additional sources if impure.
  generateSeed =
    if inPureMode
    then let
      sources = {
        inherit nixVersion langVersion nixPath storeDir;
      };

      sourceString = toJSON sources;
      hash = hashString "sha256" sourceString;

      hashToInt = str: let
        hexChars = stringToCharacters "0123456789abcdef";
        digits = stringToCharacters (substring 0 8 str);

        toNum = c:
          lib.lists.findFirstIndex (c': c' == c)
          (throw "Cannot convert hash to integer, '${c}' not in hex array!")
          hexChars;
      in
        foldl (acc: d: acc * 16 + toNum d) 0 digits;
    in
      hashToInt hash
    else let
      timeSeed = currentTime;
      systemSeed = currentSystem;
      combined = hashString "sha256" (toString timeSeed + systemSeed);

      toNum = str:
        foldl
        (acc: c: (acc * 16) + (lib.lists.findFirstIndex (x: x == c) 0 (stringToCharacters "0123456789abcdef")))
        0
        (stringToCharacters (substring 0 8 str));
    in
      toNum combined;

  getRandom = seed: let
    a = 1664525; # Park-Miller multiplier.
    m = MAX_WORD;
    x = mod seed m;
    value = x / m;
  in {
    inherit value;
    nextSeed = mod (a * seed) m;
  };
in {
  mkRandom = {seed ? generateSeed}: {
    random = getRandom;

    randomInt = {
      seed,
      min,
      max,
    }: let
      result = getRandom seed;
      span = max - min + 1;
      raw = result.value * span;
      value = floor (min + raw);
    in {
      inherit (result) nextSeed;
      inherit value;
    };

    initialSeed = seed;
  };
}
