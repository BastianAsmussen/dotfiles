{inputs, ...}: {
  flake.nixosModules.impermanence = {
    config,
    lib,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.persistence;
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
            ++ cfg.directories;

          files =
            [
              "/etc/machine-id"
            ]
            ++ cfg.files;
        };

        "${cfg.persistPath}/userdata".users.${user} = {
          inherit (cfg.user) directories files;
        };

        "${cfg.persistPath}/usercache".users.${user} = {
          inherit (cfg.user.cache) directories files;
        };
      };
    };
  };
}
