{
  flake.nixosModules.arcticVault =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkIf
        types
        ;

      cfg = config.arcticVault;
      user = config.preferences.user.name;

      inherit (config.users.users.${user}) home;

      recipientArgs = lib.concatMapStringsSep " " (r: "-r ${lib.escapeShellArg r}") cfg.recipients;

      # Resolve source paths: relative paths are anchored to $HOME, absolute paths pass through.
      resolvePaths = map (s: if lib.hasPrefix "/" s then s else "${home}/${s}");
      resolvedSources = resolvePaths cfg.sources;

      sourceArgs = lib.concatMapStringsSep " " lib.escapeShellArg resolvedSources;

      snapshotScript = pkgs.writeShellScript "arctic-vault-snapshot" ''
        set -euo pipefail

        timestamp="$(date +${cfg.timestampFormat})"
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
    in
    {
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
          example = [
            "dotfiles"
            "nix-secrets"
            ".password-store"
          ];
        };

        recipients = mkOption {
          type = types.listOf types.str;
          description = "Age public keys to encrypt snapshots to.";
          example = [ "age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ];
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

        timestampFormat = mkOption {
          type = types.str;
          default = "%Y-%m";
          description = "date(1) format string used in snapshot filenames. Must be fine-grained enough to avoid collisions at the chosen calendar frequency.";
        };

        retention = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Months to keep snapshots. Null means keep all.";
        };

        # The full archive above is the right shape for a handful of small,
        # irreplaceable things: restoring it needs only age, tar and zstd, with
        # no repo format and no repo key that might itself be locked inside the
        # thing you cannot open. It is the wrong shape for bulk data, where a
        # fresh copy every run fills the disk in weeks. Anything large goes
        # through restic instead, on the same disk.
        incremental = {
          enable = mkEnableOption "Deduplicating incremental snapshots (restic) alongside the full archive";

          passwordFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              File holding the restic repository password.

              Back this up somewhere other than the vault: without it the
              repository cannot be read, and a copy stored only inside the
              thing it unlocks is not a backup.
            '';
          };

          paths = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Paths to back up. Relative paths are resolved from the user's home directory; absolute paths are used as-is.";
            example = [
              "Documents"
              "Projects"
            ];
          };

          exclude = mkOption {
            type = types.listOf types.str;
            default = [
              "node_modules"
              "target"
              ".venv"
              "__pycache__"
              ".direnv"
              ".mypy_cache"
              ".pytest_cache"
              "zig-cache"
              "zig-out"
              "result"
              "result-*"
            ];

            description = ''
              Patterns to skip. The defaults are build output and dependency
              trees, which are large, rebuildable, and churn every commit.

              Cargo tags its own `target` directories with CACHEDIR.TAG, which
              `--exclude-caching` already catches; the literal entry here only
              covers directories left by versions predating that.
            '';
          };

          calendar = mkOption {
            type = types.str;
            default = "weekly";
            description = "systemd OnCalendar expression for the incremental run.";
          };

          pruneOpts = mkOption {
            type = types.listOf types.str;
            default = [
              "--keep-daily 7"
              "--keep-weekly 5"
              "--keep-monthly 12"
              "--keep-yearly 3"
            ];

            description = "Retention policy passed to `restic forget`.";
          };
        };
      };

      config = mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.recipients != [ ];
            message = "arcticVault.recipients must contain at least one age public key.";
          }
          {
            assertion = cfg.sources != [ ];
            message = "arcticVault.sources must contain at least one path.";
          }
          {
            assertion = !cfg.incremental.enable || cfg.incremental.passwordFile != null;
            message = "arcticVault.incremental.passwordFile must be set when incremental snapshots are enabled.";
          }
          {
            assertion = !cfg.incremental.enable || cfg.incremental.paths != [ ];
            message = "arcticVault.incremental.paths must contain at least one path when incremental snapshots are enabled.";
          }
        ];

        # Restic re-reads the pack index from the repository whenever its cache
        # is missing, and root is a tmpfs here. Only epsilon imports this module
        # and it has preservation, so no optionalAttrs guard is needed.
        persistence.directories = lib.optionals cfg.incremental.enable [
          {
            directory = "/root/.cache/restic";
            mode = "0700";
          }
        ];

        services.restic.backups = lib.mkIf cfg.incremental.enable {
          arctic-vault = {
            inherit (cfg.incremental) exclude passwordFile pruneOpts;

            repository = "${cfg.mountpoint}/restic";
            paths = resolvePaths cfg.incremental.paths;
            initialize = true;

            # Verify a slice of the data on every run. The full-archive job
            # checks nothing, which is how a backup rots unnoticed.
            runCheck = true;
            checkOpts = [ "--read-data-subset=5%" ];

            # Gives a `restic-arctic-vault` wrapper with the repository and
            # password already set, so a restore does not start with guessing
            # environment variables.
            createWrapper = true;

            extraBackupArgs = [
              # Cargo and friends drop CACHEDIR.TAG in their build directories.
              "--exclude-caching"
            ];

            timerConfig = {
              OnCalendar = cfg.incremental.calendar;
              Persistent = true;
              RandomizedDelaySec = "2h";
            };
          };
        };

        # The vault disk is nofail and may genuinely be absent.
        systemd.services.restic-backups-arctic-vault = lib.mkIf cfg.incremental.enable {
          unitConfig.RequiresMountsFor = [ cfg.mountpoint ];
        };

        systemd = {
          services.arctic-vault = {
            description = "Arctic vault: encrypted archival snapshot";
            after = [ "local-fs.target" ];
            wants = [ "local-fs.target" ];

            # Run as the user so we can read ~/dotfiles etc.
            serviceConfig = {
              Type = "oneshot";
              ExecStart = snapshotScript;
              User = user;
              Group = user;

              # The vault mountpoint must be writable by the user.
              ReadWritePaths = [ cfg.mountpoint ];
            };
          };

          timers.arctic-vault = {
            description = "Monthly arctic vault snapshot";
            wantedBy = [ "timers.target" ];
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
