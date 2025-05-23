{lib}: let
  inherit (builtins) attrNames readDir filter;
  inherit (lib.strings) hasSuffix hasPrefix;

  # Create a full key set with all properties.
  makeKey = dir: name: rec {
    inherit name dir;

    fullPath = dir + "/${name}";

    isPublic = hasSuffix ".pub" name;
    isGpg = hasSuffix ".asc" name;
    isSsh = (hasPrefix "ssh-" name) && isPublic;
    isBuilder = (hasPrefix "builder-" name) && isPublic;
  };

  # Create a collection with accessor properties.
  makeKeyCollection = dir: keys: rec {
    root = dir;
    all = keys;
    fullPaths = map (k: k.fullPath) keys;

    # Type-based collections.
    publicKeys = filter (k: k.isPublic) keys;
    gpgKeys = filter (k: k.isGpg) keys;
    sshKeys = filter (k: k.isSsh) keys;
    builderKeys = filter (k: k.isBuilder) keys;

    # Direct property access for paths.
    publicPaths = map (k: k.fullPath) publicKeys;
    gpgPaths = map (k: k.fullPath) gpgKeys;
    sshPaths = map (k: k.fullPath) sshKeys;
    builderPaths = map (k: k.fullPath) builderKeys;
  };

  defaultDir = ../keys;
in rec {
  # Main entry points.
  load = dir: let
    keyNames = attrNames (readDir dir);
    keySets = map (name: makeKey dir name) keyNames;
  in
    makeKeyCollection dir keySets;

  default = load defaultDir;
}
