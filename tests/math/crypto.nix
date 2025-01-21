{lib}: let
  inherit (lib.custom.math) isPrime rsaKeypair rsaEncrypt rsaDecrypt;
in {
  # Edge Cases.
  testIsPrimeZero = {
    expr = isPrime 0;
    expected = false;
  };

  testIsPrimeOne = {
    expr = isPrime 1;
    expected = false;
  };

  testIsPrimeNegative = {
    expr = isPrime (-5);
    expected = false;
  };

  testIsPrimeFloat = {
    expr = isPrime 3.14;
    expected = false;
  };

  # Small Numbers (1-10).
  testIsPrimeTwo = {
    expr = isPrime 2;
    expected = true;
  };

  testIsPrimeThree = {
    expr = isPrime 3;
    expected = true;
  };

  testIsPrimeFour = {
    expr = isPrime 4;
    expected = false;
  };

  testIsPrimeFive = {
    expr = isPrime 5;
    expected = true;
  };

  testIsPrimeSix = {
    expr = isPrime 6;
    expected = false;
  };

  testIsPrimeSeven = {
    expr = isPrime 7;
    expected = true;
  };

  testIsPrimeEight = {
    expr = isPrime 8;
    expected = false;
  };

  testIsPrimeNine = {
    expr = isPrime 9;
    expected = false;
  };

  testIsPrimeTen = {
    expr = isPrime 10;
    expected = false;
  };

  # Larger Numbers.
  testIsPrime97 = {
    expr = isPrime 97;
    expected = true;
  };

  testIsPrime99 = {
    expr = isPrime 99;
    expected = false;
  };

  # Perfect Squares.
  testIsPrime25 = {
    expr = isPrime 25;
    expected = false;
  };

  # Basic RSA encryption/decryption test with small primes.
  testRSABasic = let
    keys = rsaKeypair 61 53;
    msg = 42;
    cipher = rsaEncrypt msg keys.public;
    decrypted = rsaDecrypt cipher keys.private;
  in {
    expr = decrypted;
    expected = msg;
  };

  # Test with message of 0.
  testRSAZero = let
    keys = rsaKeypair 61 53;
    msg = 0;
    cipher = rsaEncrypt msg keys.public;
    decrypted = rsaDecrypt cipher keys.private;
  in {
    expr = decrypted;
    expected = msg;
  };

  # Test with message equal to modulus - 1 (max value).
  testRSAMax = let
    keys = rsaKeypair 61 53;
    msg = 61 * 53 - 1;
    cipher = rsaEncrypt msg keys.public;
    decrypted = rsaDecrypt cipher keys.private;
  in {
    expr = decrypted;
    expected = msg;
  };

  # Test with different prime pair.
  testRSADifferentPrimes = let
    keys = rsaKeypair 47 43;
    msg = 42;
    cipher = rsaEncrypt msg keys.public;
    decrypted = rsaDecrypt cipher keys.private;
  in {
    expr = decrypted;
    expected = msg;
  };

  # Test error on non-prime input.
  testRSANonPrime = let
    nonPrimeKeypair = rsaKeypair 4 53;
  in {
    expr = (builtins.tryEval (builtins.deepSeq nonPrimeKeypair nonPrimeKeypair)).success;
    expected = false;
  };
}
