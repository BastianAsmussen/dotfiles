{lib}: let
  base = rec {
    inherit (builtins) floor ciel;

    HALF_PI = 1.5707963267948965579989817342720925807952880859375;
    PI = 3.141592653589793115997963468544185161590576171875;
    TAU = 6.28318530717958623199592693708837032318115234375;

    square = a: a * a;
    cube = a: (square a) * a;

    mod = a: n: let
      quotient = floor (a / n);
    in
      a - (n * quotient);

    isEven = n: mod n 2 == 0;
    isOdd = n: !isEven n;

    max = a: b:
      if a > b
      then a
      else b;
    min = a: b:
      if a < b
      then a
      else b;

    abs = x:
      if x < 0.0
      then (-x)
      else x;

    pow = base: exp:
      if exp == 0.0
      then 1.0
      else base * pow base (exp - 1.0);

    sqrt' = n: x: precision: iteration: maxIterations: let
      next = (x + (n / x)) / 2.0;
      diff = abs (next - x);
    in
      if iteration >= maxIterations
      then next
      else if diff < precision
      then next
      else sqrt' n next precision (iteration + 1) maxIterations;
    sqrt = n: let
      precision = 0.000001;
      maxIterations = 100;
    in
      if n < 0.0
      then throw "Cannot calculate square root of negative number!"
      else if n == 0.0
      then 0.0
      else sqrt' n (max 1.0 (n / 2.0)) precision 0 maxIterations;

    fact = n:
      if n <= 1.0
      then 1.0
      else n * fact (n - 1.0);
  };

  crypto = import ./crypto.nix {inherit base lib;};
  random = import ./random.nix {inherit base lib;};
  trigenometry = import ./trigenometry.nix {inherit base;};
in
  base // crypto // random // trigenometry
