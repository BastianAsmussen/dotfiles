{ lib }:
let
  inherit (lib.custom.units)
    mibToBytes
    rateToKiBps
    durationToSeconds
    toBinary
    ;

  mkCases =
    cases:
    builtins.listToAttrs (
      map (c: {
        inherit (c) name;

        value = {
          inherit (c) expr expected;
        };
      }) cases
    );

  mibCases = [
    {
      name = "testMibToBytesConversion";
      expr = mibToBytes 256;
      expected = 268435456;
    }
    {
      name = "testZeroMib";
      expr = mibToBytes 0;
      expected = 0;
    }
    {
      name = "testNegativeMib";
      expr = mibToBytes (-1024);
      expected = -1073741824;
    }
  ];

  rateCases = [
    {
      name = "testRateKiBToKiBps";
      expr = rateToKiBps {
        value = 5;
        unit = "KiB/s";
      };

      expected = 5;
    }
    {
      name = "testRateMiBToKiBps";
      expr = rateToKiBps {
        value = 10;
        unit = "MiB/s";
      };

      expected = 10240;
    }
    {
      name = "testRateGiBToKiBps";
      expr = rateToKiBps {
        value = 1;
        unit = "GiB/s";
      };

      expected = 1048576;
    }
    {
      name = "testRateZero";
      expr = rateToKiBps {
        value = 0;
        unit = "MiB/s";
      };

      expected = 0;
    }
    {
      name = "testRateInvalidUnitFails";
      expr =
        (builtins.tryEval (
          builtins.deepSeq (rateToKiBps {
            value = 1;
            unit = "MB/s";
          }) null
        )).success;
      expected = false;
    }
  ];

  durationCases = [
    {
      name = "testDurationSecondsToSeconds";
      expr = durationToSeconds {
        value = 60;
        unit = "seconds";
      };

      expected = 60;
    }
    {
      name = "testDurationMinutesToSeconds";
      expr = durationToSeconds {
        value = 5;
        unit = "minutes";
      };

      expected = 300;
    }
    {
      name = "testDurationHoursToSeconds";
      expr = durationToSeconds {
        value = 2;
        unit = "hours";
      };

      expected = 7200;
    }
    {
      name = "testDurationZero";
      expr = durationToSeconds {
        value = 0;
        unit = "hours";
      };

      expected = 0;
    }
    {
      name = "testDurationInvalidUnitFails";
      expr =
        (builtins.tryEval (
          builtins.deepSeq (durationToSeconds {
            value = 1;
            unit = "days";
          }) null
        )).success;
      expected = false;
    }
  ];

  toBinaryCases = [
    {
      name = "testToBinaryZero";
      expr = toBinary 0;
      expected = [ 0 ];
    }
    {
      name = "testToBinaryOne";
      expr = toBinary 1;
      expected = [ 1 ];
    }
    {
      name = "testToBinaryTwo";
      expr = toBinary 2;
      expected = [
        1
        0
      ];
    }
    {
      name = "testToBinaryThree";
      expr = toBinary 3;
      expected = [
        1
        1
      ];
    }
    {
      name = "testToBinaryEight";
      expr = toBinary 8;
      expected = [
        1
        0
        0
        0
      ];
    }
    {
      name = "testToBinaryFifteen";
      expr = toBinary 15;
      expected = [
        1
        1
        1
        1
      ];
    }
    {
      name = "testToBinary42";
      expr = toBinary 42;
      expected = [
        1
        0
        1
        0
        1
        0
      ];
    }
  ];

  pow2Inputs = [
    1
    2
    4
    8
    16
    32
    64
  ];
  pow2Cases = map (
    i:
    let
      idx = lib.lists.findFirstIndex (x: x == i) null pow2Inputs;
      zerosCount = if idx == null then 0 else idx;
      zeros = builtins.genList (_: 0) zerosCount;
      expected = [ 1 ] ++ zeros;
    in
    {
      inherit expected;

      name = "testToBinaryPowersOf2${toString i}";
      expr = toBinary i;
    }
  ) pow2Inputs;
in
mkCases (mibCases ++ rateCases ++ durationCases ++ toBinaryCases ++ pow2Cases)
