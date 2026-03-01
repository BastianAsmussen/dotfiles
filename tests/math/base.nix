{lib}: let
  inherit (lib.custom.math) mod isEven isOdd pow;

  mkCases = cases:
    builtins.listToAttrs (map (
        c: {
          inherit (c) name;

          value = {
            inherit (c) expr expected;
          };
        }
      )
      cases);

  modCases = [
    {
      name = "testMod";
      expr = mod 10 2;
      expected = 0;
    }
    {
      name = "testModWithNegative";
      expr = mod (-10) 3;
      expected = -1;
    }
    {
      name = "testModWithLargeNumbers";
      expr = mod 1000000 7;
      expected = 1;
    }
  ];

  evenOddCases = builtins.concatLists [
    (map (n: {
      name = "testIsEven${toString n}";
      expr = isEven n;
      expected = true;
    }) [8])
    (map (n: {
      name = "testIsEven${toString n}";
      expr = isEven n;
      expected = false;
    }) [5])
    (map (n: {
      name = "testIsOdd${toString n}";
      expr = isOdd n;
      expected = true;
    }) [3])
    (map (n: {
      name = "testIsOdd${toString n}";
      expr = isOdd n;
      expected = false;
    }) [10])
  ];

  powCases =
    map (
      t: {
        inherit (t) expected;

        name = "testPow_${toString t.base}_exp_${toString t.exp}";
        expr = pow t.base t.exp;
      }
    ) [
      {
        base = 2;
        exp = 0;
        expected = 1;
      }
      {
        base = 5;
        exp = 1;
        expected = 5;
      }
      {
        base = 3;
        exp = 2;
        expected = 9;
      }
      {
        base = -2;
        exp = 3;
        expected = -8;
      }
      {
        base = 2;
        exp = 10;
        expected = 1024;
      }
      {
        base = 1;
        exp = 1000;
        expected = 1;
      }
      {
        base = 0;
        exp = 5;
        expected = 0;
      }
    ];
in
  mkCases (modCases ++ evenOddCases ++ powCases)
