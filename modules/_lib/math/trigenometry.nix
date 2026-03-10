{base}: let
  inherit (base) square mod TAU HALF_PI floor PI;

  # Pre-computed values of -1/3!, 1/5!, -1/7!, and so on.
  S1 = -0.1666666666666666574148081281236954964697360992431640625;
  S2 = 0.00833333333333333321768510160154619370587170124053955078125;
  S3 = -0.0001984126984126984125263171154784913596813566982746124267578125;
  S4 = 0.000002755731922398589251095059327045788677423843182623386383056640625;
  S5 = -0.0000000250521083854417202238661793213536643776251366944052278995513916015625;
  S6 = 0.0000000001605904383682161334086291829494519585452838583705670316703617572784423828125;

  # Pre-computed values of 1/2!, -1/4!, 1/6!, and so on.
  CS2 = 0.5;
  CS4 = -0.041666666666666664353702032030923874117434024810791015625;
  CS6 = 0.00138888888888888894189432843262466121814213693141937255859375;
  CS8 = -0.000024801587301587301587301587301587301587301587301587301587301587;
  CS10 = 2.7557319223985890652557319223985890652557319223985890652557e-7;
  CS12 = -2.087675698786809897921009032120143231254342365123456789e-9;

  normalizeAngle = x: let
    normalized = mod x TAU;
    k = floor (normalized / HALF_PI);
  in {
    angle = normalized;
    quadrant = mod k 4;
    offset = normalized - (k * HALF_PI);
  };

  # Small-interval polynomials assume |x| <= PI/4 for better convergence.
  computeSinSmall = x: let
    x2 = square x;
    x3 = x * x2;

    # Use sine series up to x^13.
    part1 = S2 + x2 * (S3 + x2 * (S4 + x2 * (S5 + x2 * S6)));
  in
    x + x3 * (S1 + x2 * part1);

  computeCosSmall = x: let
    x2 = square x;

    # Cosine series up to x^12.
    part1 = CS2 + x2 * (CS4 + x2 * (CS6 + x2 * (CS8 + x2 * (CS10 + x2 * CS12))));
  in
    1.0 - (x2 * part1);

  # (Co)sine using quadrant handling + interval reduction to <= PI/4.
  sin = x: let
    norm = normalizeAngle x;
    off = norm.offset;

    # Lazily-evaluated values so we don't repeat computations.
    offLeqPi4 = off <= (PI / 4.0);

    sinOff = computeSinSmall off;
    cosOff = computeCosSmall off;

    halfOff = HALF_PI - off;
    sinHalfOff = computeSinSmall halfOff;
    cosHalfOff = computeCosSmall halfOff;

    # Evaluation for quadrant 0 (the "base" value).
    evalQ0 =
      if offLeqPi4
      then sinOff
      else cosHalfOff;

    # Evaluation for quadrant 1.
    evalQ1 =
      if offLeqPi4
      then cosOff
      else sinHalfOff;
  in
    if norm.quadrant == 0
    then evalQ0
    # Evaluation for quadrant 2 and 3 reuse evalQ0 / evalQ1 with sign flips.
    else if norm.quadrant == 1
    then evalQ1
    else if norm.quadrant == 2
    then -evalQ0
    else -evalQ1;

  cos = x: sin (x + HALF_PI);
  tan = x: let
    cosX = cos x;
  in
    if cosX == 0.0
    then (throw "`cos x` cannot equal 0!")
    else (sin x) / cosX;
in {
  inherit sin cos tan;
}
