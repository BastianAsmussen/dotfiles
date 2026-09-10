# Lets a home module declare its own persisted state instead of the host
# listing it. Home-manager cannot define NixOS options, but home-manager is
# itself a NixOS module here, so the preservation module reads these back out
# of config.home-manager.users.<name> and folds them into preserveAt.
#
# Declaring only. Hosts without impermanence still evaluate this; nothing
# reads the values there.
{
  flake.homeModules.persistence =
    { lib, ... }:
    let
      inherit (lib) mkOption types;

      dirs =
        description:
        mkOption {
          type = types.listOf (types.either types.str types.attrs);
          default = [ ];
          inherit description;
        };

      files =
        description:
        mkOption {
          type = types.listOf types.str;
          default = [ ];
          inherit description;
        };
    in
    {
      options.persistence = {
        directories = dirs "Directories under the home directory to persist, relative to it.";

        directoriesWithMode = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Directories to persist with an explicit mode. Keys are paths relative to the home directory, values are mode strings (e.g. \"0700\").";
        };

        files = files "Files under the home directory to persist, relative to it.";

        cache = {
          directories = dirs "Cache directories to persist. Rebuildable, so they are kept apart from real state.";
          files = files "Cache files to persist.";
        };
      };
    };
}
