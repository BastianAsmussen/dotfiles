{
  flake.nixosModules.arcticVault = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkEnableOption mkIf types;

    cfg = config.arcticVault;
    user = config.preferences.user.name;

    inherit (config.users.users.${user}) home;

    recipientArgs = lib.concatMapStringsSep " " (r: "-r ${lib.escapeShellArg r}") cfg.recipients;

    # Resolve source paths: relative paths are anchored to $HOME, absolute paths pass through.
    resolvedSources = map (s:
      if lib.hasPrefix "/" s
      then s
      else "${home}/${s}")
    cfg.sources;

    sourceArgs = lib.concatMapStringsSep " " lib.escapeShellArg resolvedSources;

    snapshotScript = pkgs.writeShellScript "arctic-vault-snapshot" ''
      set -euo pipefail

      timestamp="$(date +%Y-%m)"
      dest="${cfg.mountpoint}/vault-''${timestamp}.tar.zst.age"

      if [ -f "$dest" ]; then
        echo "Snapshot vault-''${timestamp} already exists, skipping."
        exit 0
      fi

      echo "Creating arctic vault snapshot: vault-''${timestamp}"

      # Verify all sources exist before starting.
      for src in ${sourceArgs}; do
        if [ ! -e "$src" ]; then
          echo "ERROR: Source does not exist: $src" >&2
          exit 1
        fi
      done

      tmp="$(mktemp -p "${cfg.mountpoint}" .vault-XXXXXX.tmp)"
      trap 'rm -f "$tmp"' EXIT

      ${lib.getExe pkgs.gnutar} \
        --create \
        --absolute-names \
        --exclude-vcs-ignores \
        ${lib.concatMapStringsSep " " (s: lib.escapeShellArg s) resolvedSources} \
      | ${lib.getExe pkgs.zstd} --ultra -${toString cfg.compressionLevel} -T0 \
      | ${lib.getExe pkgs.age} --encrypt ${recipientArgs} -o "$tmp"

      mv "$tmp" "$dest"
      chmod 0400 "$dest"
      trap - EXIT

      echo "Snapshot written: $dest ($(du -h "$dest" | cut -f1))"

      ${lib.optionalString (cfg.retention != null) ''
        echo "Pruning snapshots older than ${toString cfg.retention} months..."
        ${lib.getExe pkgs.findutils} "${cfg.mountpoint}" \
          -maxdepth 1 \
          -name 'vault-*.tar.zst.age' \
          -mtime +${toString (cfg.retention * 31)} \
          -print -delete
      ''}
    '';
  in {
    options.arcticVault = {
      enable = mkEnableOption "Monthly encrypted archival snapshots (arctic vault).";
      mountpoint = mkOption {
        type = types.str;
        default = "/srv/arctic-vault";
        description = "Where the vault partition is mounted.";
      };

      sources = mkOption {
        type = types.listOf types.str;
        description = ''
          Paths to include in the snapshot. Relative paths are resolved from
          the user's home directory; absolute paths are used as-is.
        '';
        example = ["dotfiles" "nix-secrets" ".password-store"];
      };

      recipients = mkOption {
        type = types.listOf types.str;
        description = "Age public keys to encrypt snapshots to.";
        example = ["age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"];
      };

      compressionLevel = mkOption {
        type = types.ints.between 1 22;
        default = 22;
        description = "Zstandard compression level (22 = --ultra max).";
      };

      calendar = mkOption {
        type = types.str;
        default = "monthly";
        description = "systemd OnCalendar expression for snapshot frequency.";
      };

      retention = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "Months to keep snapshots. Null means keep all.";
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.recipients != [];
          message = "arcticVault.recipients must contain at least one age public key.";
        }
        {
          assertion = cfg.sources != [];
          message = "arcticVault.sources must contain at least one path.";
        }
      ];

      systemd = {
        services.arctic-vault = {
          description = "Arctic vault: encrypted archival snapshot";
          after = ["local-fs.target"];
          wants = ["local-fs.target"];

          # Run as the user so we can read ~/dotfiles etc.
          serviceConfig = {
            Type = "oneshot";
            ExecStart = snapshotScript;
            User = user;
            Group = user;

            # The vault mountpoint must be writable by the user.
            ReadWritePaths = [cfg.mountpoint];
          };
        };

        timers.arctic-vault = {
          description = "Monthly arctic vault snapshot";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = cfg.calendar;
            Persistent = true; # Fire on next boot if a run was missed.
            RandomizedDelaySec = "6h";
          };
        };
      };
    };
  };
}
