lib: let
  custom = lib.makeExtensible (_self: let
    callLibs = file: import file {inherit lib;};
  in {
    math = callLibs ./math;
    keys = callLibs ./keys.nix;
    units = callLibs ./units.nix;
  });
in
  custom
