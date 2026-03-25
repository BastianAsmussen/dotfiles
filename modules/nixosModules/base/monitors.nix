{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.monitors = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          primary = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };

          width = lib.mkOption {
            type = lib.types.int;
            example = 1920;
          };

          height = lib.mkOption {
            type = lib.types.int;
            example = 1080;
          };

          refreshRate = lib.mkOption {
            type = lib.types.float;
            default = 60.0;
          };

          x = lib.mkOption {
            type = lib.types.int;
            default = 0;
          };

          y = lib.mkOption {
            type = lib.types.int;
            default = 0;
          };

          scale = lib.mkOption {
            type = lib.types.float;
            default = 1.0;
            description = "Output scale factor.";
          };

          vrr = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable variable refresh rate (VRR / FreeSync / G-Sync).";
          };

          enabled = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      });

      default = {};
      description = "Per-host monitor configuration used to generate compositor output settings.";
    };
  };
}
