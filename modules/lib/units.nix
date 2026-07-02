{ config, ... }:
{
  customLib.units =
    let
      inherit (config.customLib.math) mod;

      getMultiplier =
        kind: unit: multipliers:
        multipliers.${unit} or (throw "Unsupported ${kind} unit: ${unit}");
    in
    {
      mibToBytes = mib: mib * 1024 * 1024;

      rateToKiBps =
        {
          value,
          unit,
        }:
        let
          multipliers = {
            "KiB/s" = 1;
            "MiB/s" = 1024;
            "GiB/s" = 1024 * 1024;
          };
        in
        value * getMultiplier "rate" unit multipliers;

      durationToSeconds =
        {
          value,
          unit,
        }:
        let
          multipliers = {
            seconds = 1;
            minutes = 60;
            hours = 60 * 60;
          };
        in
        value * getMultiplier "duration" unit multipliers;

      # Decompose integer into list of bits (MSB first).
      # Each iteration prepends the current LSB since we extract LSB first and
      # prepend, the MSB naturally ends up at the head.
      toBinary =
        n:
        let
          go =
            acc: remaining: if remaining == 0 then acc else go ([ (mod remaining 2) ] ++ acc) (remaining / 2);
        in
        if n == 0 then [ 0 ] else go [ ] n;
    };
}
