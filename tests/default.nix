{
  pkgs,
  lib,
}: let
  inherit (pkgs) runCommandLocal;
  inherit (lib.generators) toPretty;

  # Get all entries in the test directory.
  contents = builtins.readDir ./.;

  # Process each entry - either a single file or a directory.
  testSuites =
    lib.mapAttrsToList (
      name: type:
        if type == "directory" || (type == "regular" && name != "default.nix")
        then pkgs.callPackage ./${name} {inherit lib;}
        else {}
    )
    contents;

  # Merge all test suites.
  mergedTests = lib.foldl (acc: suite: acc // suite) {} testSuites;
  results = lib.runTests mergedTests;
in
  if results == []
  then runCommandLocal "pass-tests" {} "touch $out"
  else
    runCommandLocal "fail-tests"
    {
      results = lib.concatStringsSep "\n" (
        map (result: ''
          ${result.name}:
            Expected: ${toPretty {} result.expected}
            Got: ${toPretty {} result.result}
        '')
        results
      );
    }
    ''
      printf "Failed Tests:\n\n%s\n" "$results" >&2
      exit 1
    ''
