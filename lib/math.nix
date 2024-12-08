rec {
  mod = a: n: let
    quotient = builtins.div a n;
  in
    a - (n * quotient);

  max = a: b:
    if a > b
    then a
    else b;
  min = a: b:
    if a < b
    then a
    else b;

  abs = x:
    if x < 0
    then (-x)
    else x;

  newtonSqrt = n: x: precision: iteration: maxIterations: let
    next = (x + (n / x)) / 2.0;
    diff = abs (next - x);
  in
    if iteration >= maxIterations
    then next
    else if diff < precision
    then next
    else newtonSqrt n next precision (iteration + 1) maxIterations;
  sqrt = n: {
    precision ? 0.000001,
    maxIterations ? 100,
  }:
    if n < 0
    then throw "Cannot calculate square root of negative number!"
    else if n == 0
    then 0
    else newtonSqrt n (max 1.0 (n / 2.0)) precision 0 maxIterations;
}
