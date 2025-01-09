{
  pkgs,
  lib,
}: let
  inherit (pkgs) runCommandLocal;
  inherit (lib.generators) toPretty;

  fileList = builtins.attrNames (lib.filterAttrs (name: type: name != "default.nix" && type == "regular") (builtins.readDir ./.));
  testSuites = map (file: pkgs.callPackage ./${file} {inherit lib;}) fileList;
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
