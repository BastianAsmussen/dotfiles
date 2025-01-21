{base}: let
  inherit (base) mod;

  isPrime' = n: i:
    if n <= 2
    then n == 2
    else if mod n i == 0
    then false
    else if i * i > n
    then true
    else isPrime' n (i + 1);
in {
  isPrime = n: isPrime' n 2;
}
