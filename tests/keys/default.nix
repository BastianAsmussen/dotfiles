{lib}: let
  mockDir = ./mock;
  keys = lib.custom.keys.load mockDir;
  mapKeys = ks: map (k: mockDir + "/${k}") ks;
in {
  testAllKeys = {
    expr = keys.fullPaths;
    expected = mapKeys [
      "0xDEADBEEFDEADBEEF-1970-01-01.asc"
      "builder-kappa.pub"
      "builder-sigma.pub"
      "ssh-theta.pub"
    ];
  };

  testPublicKeys = {
    expr = keys.publicPaths;
    expected = mapKeys [
      "builder-kappa.pub"
      "builder-sigma.pub"
      "ssh-theta.pub"
    ];
  };

  testGPGKeys = {
    expr = keys.gpgPaths;
    expected = mapKeys [
      "0xDEADBEEFDEADBEEF-1970-01-01.asc"
    ];
  };

  testSSHKeys = {
    expr = keys.sshPaths;
    expected = mapKeys [
      "ssh-theta.pub"
    ];
  };

  testBuilderKeys = {
    expr = keys.builderPaths;
    expected = mapKeys [
      "builder-kappa.pub"
      "builder-sigma.pub"
    ];
  };
}
