{
  inputs,
  lib,
  config,
  ...
}:
let
  withCustom =
    nixpkgsLib:
    nixpkgsLib.extend (
      _: _prev: {
        custom = config.customLib;
      }
    );
in
{
  options.customLib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.anything;
    default = { };
    description = "Custom lib helpers, populated by `modules/lib/*.nix`.";
  };

  config.flake = {
    lib = withCustom inputs.nixpkgs.lib;

    # Stable hosts must use their matching nixpkgs lib.
    libStable = withCustom inputs.nixpkgs-stable.lib;
  };
}
