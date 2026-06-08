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
    in
    {
      imports = [
        inputs.preservation.nixosModules.preservation
      ];

      options.persistence = {
        enable = mkEnableOption "Erase root on every boot (preservation)";
        tmpfsSize = mkOption {
          type = types.str;
          default = "4G";
          description = "Size of the tmpfs root filesystem.";
        };

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
              inherit (cfg.user) files;

              directories = cfg.user.directories ++ mkDirWithMode cfg.user.directoriesWithMode;
            };

            "${cfg.persistPath}/usercache".users.${user} = {
              inherit (cfg.user.cache) directories files;
            };
          };
        };
      };
    };
}
