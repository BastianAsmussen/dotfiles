{inputs, ...}: {
  flake.nixosModules.impermanence = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.persistence;
    mkDirWithMode = lib.mapAttrsToList (directory: mode: {inherit directory mode;});
    user = config.preferences.user.name;
  in {
    imports = [
      inputs.impermanence.nixosModules.impermanence
    ];

    options.persistence = {
      enable = mkEnableOption "Erase root on every boot (impermanence)";

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
        default = [];
        description = "Extra system directories to persist.";
      };

      directoriesWithMode = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra system directories to persist, with explicit permissions. Keys are paths, values are mode strings (e.g. \"0700\").";
      };

      files = mkOption {
        type = types.listOf (types.either types.str types.attrs);
        default = [];
        description = "Extra system files to persist.";
      };

      user = {
        directories = mkOption {
          type = types.listOf (types.either types.str types.attrs);
          default = [];
          description = "User directories to persist (important data).";
        };

        directoriesWithMode = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "User directories to persist, with explicit permissions. Keys are paths, values are mode strings (e.g. \"0700\").";
        };

        files = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "User files to persist.";
        };

        cache = {
          directories = mkOption {
            type = types.listOf (types.either types.str types.attrs);
            default = [];
            description = "User cache directories to persist (rebuildable).";
          };

          files = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "User cache files to persist.";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      # Persist subvolume must be available before anything else.
      fileSystems."${cfg.persistPath}".neededForBoot = true;

      # Point sops at the persist source directly, since /persist is mounted early.
      sops.age.sshKeyPaths = [
        "${cfg.persistPath}/system/etc/ssh/ssh_host_ed25519_key"
      ];

      # Allow bind-mount FUSE access for user home persistence.
      programs.fuse.userAllowOther = true;

      boot.tmp.cleanOnBoot = lib.mkDefault true;

      environment.persistence = {
        "${cfg.persistPath}/system" = {
          hideMounts = true;

          directories =
            [
              "/etc/ssh" # Host keys, sops-nix derives age identity from these.
              "/var/log"
              "/var/lib/nixos" # UID/GID map state.
              "/var/lib/systemd/timers" # Persistent timer state.
              "/var/lib/sops-nix"
            ]
            ++ cfg.directories
            ++ mkDirWithMode cfg.directoriesWithMode;

          files =
            [
              "/etc/machine-id"
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
}
