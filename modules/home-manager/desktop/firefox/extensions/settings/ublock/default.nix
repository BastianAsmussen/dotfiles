lib: let
  concatFilesFrom = dir:
    builtins.concatLists (
      map (
        file:
          lib.strings.splitString "\n" (
            builtins.readFile "${dir}/${file}"
          )
      ) (
        builtins.attrNames (builtins.readDir dir)
      )
    );
in {
  adminSettings.toOverwrite.filters = concatFilesFrom ./filters;
}
