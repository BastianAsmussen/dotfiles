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

      toBinary =
        n:
        let
          addBit =
            acc: n:
            if n == 0 then
              acc
            else
              let
                bit = mod n 2;
                next = n / 2;
              in
              addBit ([ bit ] ++ acc) next;
        in
        if n == 0 then [ 0 ] else addBit [ ] n;
    };
}
