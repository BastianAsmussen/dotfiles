# Let home modules declare persisted state for preservation to read back.
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
