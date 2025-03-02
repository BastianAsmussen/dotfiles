{base}: let
  inherit (base) square cube mod TAU HALF_PI floor;

  # Pre-computed values of -1/3!, 1/5!, -1/7!, and so on.
  S1 = -0.1666666666666666574148081281236954964697360992431640625;
  S2 = 0.00833333333333333321768510160154619370587170124053955078125;
  S3 = -0.0001984126984126984125263171154784913596813566982746124267578125;
  S4 = 0.000002755731922398589251095059327045788677423843182623386383056640625;
  S5 = -0.0000000250521083854417202238661793213536643776251366944052278995513916015625;
  S6 = 0.0000000001605904383682161334086291829494519585452838583705670316703617572784423828125;

  # Pre-computed values of 1/2!, -1/4!, and 1/6!.
  CS2 = 0.5;
  CS4 = -0.041666666666666664353702032030923874117434024810791015625;
  CS6 = 0.00138888888888888894189432843262466121814213693141937255859375;

  normalizeAngle = x: let
    normalized = mod x TAU;
    k = floor (normalized / HALF_PI);
  in {
    angle = normalized;
    quadrant = mod k 4;
    offset = normalized - (k * HALF_PI);
  };

  # Core sine computation using Taylor series.
  computeSin = x: let
    x2 = square x;
    x3 = cube x;
    part1 = S2 + x2 * (S3 + x2 * (S4 + x2 * (S5 + x2 * S6)));
  in
    x + x3 * (S1 + x2 * part1);

  # Core cosine computation using Taylor series.
  computeCos = x: let
    x2 = square x;
    part1 = CS2 + x2 * (CS4 + x2 * CS6);
  in
    1.0 - (x2 * part1);
in rec {
  sin = x: let
    norm = normalizeAngle x;
  in
    if norm.quadrant == 0
    then computeSin norm.offset
    else if norm.quadrant == 1
    then computeCos norm.offset
    else if norm.quadrant == 2
    then -computeSin norm.offset
    else -computeCos norm.offset;

  cos = x: sin (x + HALF_PI);
  tan = x: let
    cosX = cos x;
  in
    if cosX == 0.0
    then (throw "`cos x` cannot equal 0!")
    else (sin x) / cosX;
}
