{lib}: let
  mockDir = ./mock;
  keys = lib.custom.keys.load mockDir;

  mapKeys = ks: map (k: mockDir + "/${k}") ks;
in {
  testAllKeys = {
    expr = keys.fullPaths;
    expected = mapKeys [
      "0xDEADBEEFDEADBEEF-1970-01-01.asc"
      "age-alice.pub"
      "builder-kappa.pub"
      "builder-sigma.pub"
      "ssh-theta.pub"
    ];
  };

  testPublicKeys = {
    expr = keys.publicPaths;
    expected = mapKeys [
      "age-alice.pub"
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

  testAgeKeys = {
    expr = keys.agePaths;
    expected = mapKeys [
      "age-alice.pub"
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

  testFilterSshKeys = {
    expr = map (k: k.name) (lib.custom.keys.filterSshKeys ["ssh-theta.pub"] keys);
    expected = ["ssh-theta.pub"];
  };

  testFilterSshKeysExcludesNonSsh = {
    expr = lib.custom.keys.filterSshKeys ["builder-kappa.pub"] keys;
    expected = [];
  };

  testFilterSshKeysEmpty = {
    expr = lib.custom.keys.filterSshKeys [] keys;
    expected = [];
  };

  testSelectSshPaths = {
    expr = lib.custom.keys.selectSshPaths ["ssh-theta.pub"] keys;
    expected = mapKeys ["ssh-theta.pub"];
  };

  testSelectSshPathsMissingName = {
    expr = lib.custom.keys.selectSshPaths ["ssh-theta.pub" "ssh-nonexistent.pub"] keys;
    expected = mapKeys ["ssh-theta.pub"];
  };

  testSelectSshContents = {
    expr = lib.custom.keys.selectSshContents ["ssh-theta.pub"] keys;
    expected = [(builtins.readFile (mockDir + "/ssh-theta.pub"))];
  };

  testSelectSshContentsEmpty = {
    expr = lib.custom.keys.selectSshContents ["ssh-nonexistent.pub"] keys;
    expected = [];
  };

  testFilterAgeKeys = {
    expr = map (k: k.name) (lib.custom.keys.filterAgeKeys ["age-alice.pub"] keys);
    expected = ["age-alice.pub"];
  };

  testFilterAgeKeysExcludesNonAge = {
    expr = lib.custom.keys.filterAgeKeys ["builder-kappa.pub"] keys;
    expected = [];
  };

  testFilterAgeKeysEmpty = {
    expr = lib.custom.keys.filterAgeKeys [] keys;
    expected = [];
  };

  testSelectAgePaths = {
    expr = lib.custom.keys.selectAgePaths ["age-alice.pub"] keys;
    expected = mapKeys ["age-alice.pub"];
  };

  testSelectAgePathsMissingName = {
    expr = lib.custom.keys.selectAgePaths ["age-alice.pub" "age-nonexistent.pub"] keys;
    expected = mapKeys ["age-alice.pub"];
  };

  testSelectAgeContents = {
    expr = lib.custom.keys.selectAgeContents ["age-alice.pub"] keys;
    expected = [(builtins.readFile (mockDir + "/age-alice.pub"))];
  };

  testSelectAgeContentsEmpty = {
    expr = lib.custom.keys.selectAgeContents ["age-nonexistent.pub"] keys;
    expected = [];
  };
}
