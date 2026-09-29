{ lib, ... }:
{
  # Root flake inputs fetched over ssh, i.e. private repos.
  customLib.privateInputs =
    let
      lock = lib.importJSON ../../flake.lock;
    in
    builtins.attrNames (
      lib.filterAttrs (
        _: node: builtins.isString node && lib.hasPrefix "ssh://" (lock.nodes.${node}.original.url or "")
      ) lock.nodes.root.inputs
    );
}
