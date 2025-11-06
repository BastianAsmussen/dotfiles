{
  flake.nixosModules.base = {lib, ...}: let
    inherit (lib) types;
  in {
    options.preferences.autostart = lib.mkOption {
      type = types.listOf (types.either types.str types.package);
      default = [];
    };
  };
}
