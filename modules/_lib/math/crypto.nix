{
  base,
  lib,
}: let
  inherit (base) mod floor isEven square;
  inherit (builtins) foldl';

  isPrime' = n: i:
    if i * i > n
    then true
    else if mod n i == 0
    then false
    else isPrime' n (i + 2);
in rec {
  isPrime = n:
    if n != floor n || n < 2
    then false
    else if n == 2
    then true
    else if isEven n
    then false
    else isPrime' n 3;

  # Modular exponentiation: base^exp mod m.
  modExp = base: exp: m: let
    bits = lib.custom.units.toBinary exp;

    # Square-and-multiply algorithm.
    compute = acc: bit: let
      squared = mod (square acc) m;
    in
      if bit == 1
      then mod (squared * base) m
      else squared;
  in
    foldl' compute 1 bits;

  # Create RSA keypair from two primes.
  rsaKeypair = p: q: let
    # Validate prime inputs.
    checkPrime = n:
      if isPrime n
      then n
      else throw "rsaKeypair: ${toString n} is not prime!";

    p' = checkPrime p;
    q' = checkPrime q;

    # Calculate RSA parameters.
    n = p' * q';
    phi = (p' - 1) * (q' - 1);
    e = 65537; # Fermat prime F4.
    d = modInv e phi;
  in {
    public = {inherit e n;};
    private = {inherit d n;};
  };

  # RSA encryption/decryption.
  rsaEncrypt = msg: {
    e,
    n,
  }:
    modExp msg e n;
  rsaDecrypt = cipher: {
    d,
    n,
  }:
    modExp cipher d n;

  # Modular multiplicative inverse using extended Euclidean algorithm.
  modInv = a: m: let
    # Extended Euclidean algorithm.
    extGcd = a: b: let
      step = s: t: r: s': t': r':
        if r' == 0
        then s
        else let
          q = r / r';
          nextS = s - (q * s');
          nextT = t - (q * t');
          nextR = mod r r';
        in
          step s' t' r' nextS nextT nextR;
    in
      step 1 0 a 0 1 b;

    result = extGcd a m;
  in
    if result < 0
    then result + m
    else result;
}
