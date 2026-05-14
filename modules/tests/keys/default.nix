{ config, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      keysLib = config.flake.lib.custom.keys;

      mockDir = ./mock;
      keys = keysLib.load mockDir;
      mapKeys = ks: map (k: mockDir + "/${k}") ks;

      cases = {
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
          expr = map (k: k.name) (keysLib.filterSshKeys [ "ssh-theta.pub" ] keys);
          expected = [ "ssh-theta.pub" ];
        };

        testFilterSshKeysExcludesNonSsh = {
          expr = keysLib.filterSshKeys [ "builder-kappa.pub" ] keys;
          expected = [ ];
        };

        testFilterSshKeysEmpty = {
          expr = keysLib.filterSshKeys [ ] keys;
          expected = [ ];
        };

        testSelectSshPaths = {
          expr = keysLib.selectSshPaths [ "ssh-theta.pub" ] keys;
          expected = mapKeys [ "ssh-theta.pub" ];
        };

        testSelectSshPathsMissingName = {
          expr = keysLib.selectSshPaths [
            "ssh-theta.pub"
            "ssh-nonexistent.pub"
          ] keys;
          expected = mapKeys [ "ssh-theta.pub" ];
        };

        testSelectSshContents = {
          expr = keysLib.selectSshContents [ "ssh-theta.pub" ] keys;
          expected = [ (builtins.readFile (mockDir + "/ssh-theta.pub")) ];
        };

        testSelectSshContentsEmpty = {
          expr = keysLib.selectSshContents [ "ssh-nonexistent.pub" ] keys;
          expected = [ ];
        };

        testFilterAgeKeys = {
          expr = map (k: k.name) (keysLib.filterAgeKeys [ "age-alice.pub" ] keys);
          expected = [ "age-alice.pub" ];
        };

        testFilterAgeKeysExcludesNonAge = {
          expr = keysLib.filterAgeKeys [ "builder-kappa.pub" ] keys;
          expected = [ ];
        };

        testFilterAgeKeysEmpty = {
          expr = keysLib.filterAgeKeys [ ] keys;
          expected = [ ];
        };

        testSelectAgePaths = {
          expr = keysLib.selectAgePaths [ "age-alice.pub" ] keys;
          expected = mapKeys [ "age-alice.pub" ];
        };

        testSelectAgePathsMissingName = {
          expr = keysLib.selectAgePaths [
            "age-alice.pub"
            "age-nonexistent.pub"
          ] keys;
          expected = mapKeys [ "age-alice.pub" ];
        };

        testSelectAgeContents = {
          expr = keysLib.selectAgeContents [ "age-alice.pub" ] keys;
          expected = [ (builtins.readFile (mockDir + "/age-alice.pub")) ];
        };

        testSelectAgeContentsEmpty = {
          expr = keysLib.selectAgeContents [ "age-nonexistent.pub" ] keys;
          expected = [ ];
        };
      };

      results = lib.runTests cases;
    in
    {
      checks.tests-keys =
        if results == [ ] then
          pkgs.runCommandLocal "tests-keys-pass" { } "touch $out"
        else
          pkgs.runCommandLocal "tests-keys-fail"
            {
              RESULTS = lib.concatStringsSep "\n" (
                map (r: ''
                  ${r.name}:
                    expected: ${lib.generators.toPretty { } r.expected}
                    got:      ${lib.generators.toPretty { } r.result}
                '') results
              );
            }
            ''
              printf "Failed Tests:\n\n%s\n" "$RESULTS" >&2
              exit 1
            '';
    };
}
