{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.autostart = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [];
      description = "List of programs or shell scripts to launch at compositor startup.";
    };
  };
}
