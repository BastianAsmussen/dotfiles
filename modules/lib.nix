{
  inputs,
  lib,
  config,
  ...
}:
{
  options.customLib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.anything;
    default = { };
    description = "Custom lib helpers, populated by `modules/lib/*.nix`.";
  };

  config.flake.lib = inputs.nixpkgs.lib.extend (
    _: _prev: {
      custom = config.customLib;
    }
  );
}
