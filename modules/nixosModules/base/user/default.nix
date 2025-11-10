{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.user = let
      inherit (lib) mkOption types;
    in {
      name = mkOption {
        type = types.str;
        default = "bastian";
      };

      description = mkOption {
        type = types.str;
        default = "Bastian Asmussen";
      };

      icon = mkOption {
        type = types.path;
        default = ./bastian.png;
      };
    };
  };
}
