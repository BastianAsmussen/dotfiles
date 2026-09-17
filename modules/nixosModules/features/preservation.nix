{ inputs, ... }:
{
  flake.nixosModules.preservation =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkIf
        mkDefault
        types
        ;

      cfg = config.persistence;
      mkDirWithMode = lib.mapAttrsToList (directory: mode: { inherit directory mode; });
      user = config.preferences.user.name;

      dirWithModeType = types.submodule {
        options = {
          mode = mkOption {
            type = types.str;
            description = "Directory mode, e.g. \"0700\".";
          };

          user = mkOption {
            type = types.str;
            default = "root";
            description = "Owning user.";
          };

          group = mkOption {
            type = types.str;
            default = "root";
            description = "Owning group.";
          };
        };
      };

      # Read home-module persistence declarations into the NixOS configuration.
      homeCfg =
        config.home-manager.users.${user}.persistence or {
          directories = [ ];
          directoriesWithMode = { };
          files = [ ];
          cache = {
            directories = [ ];
            files = [ ];
          };
        };
    in
    {
      imports = [
        inputs.preservation.nixosModules.preservation
      ];

      options.persistence = {
        enable = mkEnableOption "Erase root on every boot (preservation)";
        persistPath = mkOption {
          type = types.str;
          default = "/persist";
          description = "Base path for persistent storage.";
        };

        directories = mkOption {
          type = types.listOf (types.either types.str types.attrs);
          default = [ ];
          description = "Extra system directories to persist.";
        };

        directoriesWithMode = mkOption {
          type = types.attrsOf dirWithModeType;
          default = { };
          description = "Extra system directories to persist, with explicit permissions. Keys are paths, values set the mode and owner.";
        };

        files = mkOption {
          type = types.listOf (types.either types.str types.attrs);
          default = [ ];
          description = "Extra system files to persist.";
        };

        user = {
          directories = mkOption {
            type = types.listOf (types.either types.str types.attrs);
            default = [ ];
            description = "User directories to persist (important data).";
          };

          directoriesWithMode = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "User directories to persist, with explicit permissions. Keys are paths, values are mode strings (e.g. \"0700\").";
          };

          files = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "User files to persist.";
          };

          cache = {
            directories = mkOption {
              type = types.listOf (types.either types.str types.attrs);
              default = [ ];
              description = "User cache directories to persist (rebuildable).";
            };

            files = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "User cache files to persist.";
            };
          };
        };
      };

      config = mkIf cfg.enable {
        fileSystems."${cfg.persistPath}".neededForBoot = true;

        sops.age.sshKeyPaths = [
          "${cfg.persistPath}/system/etc/ssh/ssh_host_ed25519_key"
        ];

        systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
        boot = {
          initrd.systemd.enable = mkDefault true;
          tmp = {
            useTmpfs = false;
            cleanOnBoot = mkDefault true;
          };
        };

        preservation = {
          enable = true;

          preserveAt = {
            "${cfg.persistPath}/system" = {
              directories = [
                # Mount /etc/ssh in initrd before setup-etc installs its config
                # symlinks.
                {
                  directory = "/etc/ssh";
                  inInitrd = true;
                }
                "/var/log"
                "/var/lib/nixos"
                "/var/lib/systemd/timers"
                "/var/lib/sops-nix"
              ]
              ++ cfg.directories
              ++ lib.mapAttrsToList (directory: dir: {
                inherit directory;
                inherit (dir) mode user group;
              }) cfg.directoriesWithMode;

              files = [
                {
                  file = "/etc/machine-id";
                  inInitrd = true;
                }
              ]
              ++ cfg.files;
            };

            "${cfg.persistPath}/userdata".users.${user} = {
              files = cfg.user.files ++ homeCfg.files;

              directories =
                cfg.user.directories
                ++ mkDirWithMode cfg.user.directoriesWithMode
                ++ homeCfg.directories
                ++ mkDirWithMode homeCfg.directoriesWithMode;
            };

            "${cfg.persistPath}/usercache".users.${user} = {
              directories = cfg.user.cache.directories ++ homeCfg.cache.directories;
              files = cfg.user.cache.files ++ homeCfg.cache.files;
            };
          };
        };
      };
    };
}
