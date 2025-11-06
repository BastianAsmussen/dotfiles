{
  flake.nixosModules.base = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) types;
  in {
    options.preferences.keymap = lib.mkOption {
      type = types.lazyAttrsOf (types.either types.attrs types.package);
      default = {};
      example = {
        # super + d and f keychord.
        "SUPER + d"."f".exec = "firefox";

        # super + a and b and c keychord.
        "SUPER + a"."b"."c".exec = "pcmanfm";
        "a" = {
          package = pkgs.firefox;
          exec = "pcmanfm";
        };
      };
    };
  };
}
