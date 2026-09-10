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

      # Home modules own the paths under ~ that belong to them, but cannot
      # define NixOS options, so their definitions are read back out of the
      # home-manager submodule. Nothing on the home side reads these, so
      # there is no cycle.
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
          type = types.attrsOf types.str;
          default = { };
          description = "Extra system directories to persist, with explicit permissions. Keys are paths, values are mode strings (e.g. \"0700\").";
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
                # Mount in initrd so the bind-mount is active before stage-2
                # `setup-etc` runs. Otherwise setup-etc writes the sshd_config /
                # ssh_config / moduli symlinks onto the tmpfs /etc/ssh and the
                # later bind-mount shadows them, leaving sshd with no config on a
                # freshly-installed host (it works on long-lived hosts only
                # because repeated switches eventually populate /persist).
                # /persist is neededForBoot, so it is available in initrd.
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
              ++ mkDirWithMode cfg.directoriesWithMode;

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
