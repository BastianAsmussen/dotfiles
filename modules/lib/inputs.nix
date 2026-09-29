{ lib, ... }:
let
  lock = lib.importJSON ../../flake.lock;
  root = ../..;

  # Root flake inputs fetched over ssh, i.e. private repos.
  privateInputs = builtins.attrNames (
    lib.filterAttrs (
      _: node: builtins.isString node && lib.hasPrefix "ssh://" (lock.nodes.${node}.original.url or "")
    ) lock.nodes.root.inputs
  );

  # POSIX regex has no lookahead, so the follow-up token is captured and judged in `allowed`.
  pattern = ''inputs\.(${lib.concatStringsSep "|" privateInputs})(\.[A-Za-z_"][A-Za-z0-9_"'-]*|[^A-Za-z0-9_.-]|$)'';

  allowed =
    before: next: after:
    (lib.hasPrefix "." next && next != ".outPath")
    || (
      next == ")"
      && builtins.match ".*inherit[[:space:]]*\\([[:space:]]*" before != null
      && builtins.match "[[:space:]]*[A-Za-z_\"].*" after != null
    );

  lineHit =
    line:
    let
      parts = builtins.split pattern line;
    in
    lib.any (
      i:
      let
        part = builtins.elemAt parts i;
      in
      builtins.isList part
      && !allowed (builtins.elemAt parts (i - 1)) (builtins.elemAt part 1) (builtins.elemAt parts (i + 1))
    ) (lib.range 0 (builtins.length parts - 1));

  fileHits =
    file:
    let
      rel = lib.removePrefix "${toString root}/" (toString file);
    in
    lib.concatLists (
      lib.imap1 (n: line: lib.optional (lineHit line) "${rel}:${toString n}: ${lib.trim line}") (
        lib.splitString "\n" (builtins.readFile file)
      )
    );
in
{
  customLib = {
    inherit privateInputs;

    # Every line that reaches a private input's source instead of its outputs.
    privateInputAccess = lib.concatMap fileHits (
      builtins.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive root)
    );
  };
}
