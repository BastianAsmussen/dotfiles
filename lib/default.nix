lib: let
  custom = lib.makeExtensible (_self: let
    callLibs = file: import file {inherit lib;};
  in {
    math = callLibs ./math.nix;
  });
in
  custom
