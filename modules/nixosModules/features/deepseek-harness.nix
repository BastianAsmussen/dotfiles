{
  flake.nixosModules.deepseekHarness =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        ;

      cfg = config.deepseek-harness;

      # Checkout names derive from container mount paths.
      checkoutName = mount: lib.removePrefix "-" (lib.replaceStrings [ "/" ] [ "-" ] mount);
      checkoutNames = lib.mapAttrsToList (mount: _: checkoutName mount) cfg.checkouts;

      # Quote the checkout table literally so paths cannot execute as shell
      # code.
      checkoutTable = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          mount: checkout: "${checkoutName mount}\t${mount}\t${toString checkout.source}"
        ) cfg.checkouts
      );

      dshWorkspace =
        pkgs.writeShellScriptBin "dsh-workspace"
          # sh
          ''
            export PATH=${
              lib.makeBinPath [
                pkgs.rsync
                pkgs.diffutils
                pkgs.util-linux
              ]
            }:$PATH

            set -euo pipefail

            stateDir='${cfg.stateDir}'
            checkouts='${checkoutTable}'
            root="$stateDir/workspaces"

            # @describe Disposable checkouts of the directories exposed to dsh.
            # The source is mounted read-only; work happens in a private copy under
            # the state directory, so arbitrary commands can run without touching
            # the original tree.

            function resolve {
                local want=$1 mount="" source=""
                while IFS=$'\t' read -r name mount source; do
                    if [ "$name" = "$want" ]; then
                        break
                    fi
                    mount="" source=""
                done < <(printf '%s\n' "$checkouts")

                if [ -z "$mount" ]; then
                    echo "dsh-workspace: unknown checkout '$want'" >&2
                    exit 1
                fi

                if [ -d "$mount" ]; then
                    SRC=$mount
                elif [ -d "$source" ]; then
                    SRC=$source
                else
                    echo "dsh-workspace: source of checkout '$want' found neither at '$mount' (container) nor '$source' (host)" >&2
                    exit 1
                fi

                WS="$root/$want"
            }

            # @cmd Create or refresh checkout NAME from its source (mirrors exactly: files removed upstream or edited locally vanish on re-open).
            # @arg name Checkout name (`list` shows them)
            function open {
                resolve "$argc_name"
                mkdir -p "$WS"
                rsync -a --delete "$SRC/" "$WS/"
                echo "checked out '$SRC' -> '$WS'"
            }

            # @cmd Present what apply would change (unified diff).
            # @arg name Checkout name
            function diff {
                resolve "$argc_name"
                if ! [ -d "$WS" ]; then
                    echo "dsh-workspace: no checkout '$argc_name' (open one first)" >&2
                    exit 1
                fi

                # `command`: the diff function would otherwise shadow the binary.
                set +e
                command diff -ruN --exclude=.git --exclude=result "$SRC" "$WS"
                local rc=$?
                set -e

                if [ "$rc" -eq 0 ]; then
                    echo "no differences"
                elif [ "$rc" -gt 1 ]; then
                    exit "$rc"
                fi
            }

            # @cmd Promote the checkout back onto the source. Destructive; host-only, as the container sees the mount read-only.
            # @arg name Checkout name
            function apply {
                resolve "$argc_name"
                if ! [ -d "$WS" ]; then
                    echo "dsh-workspace: no checkout '$argc_name' (open one first)" >&2
                    exit 1
                fi

                local opts
                opts=$(findmnt -uno OPTIONS -T "$SRC" 2>/dev/null || true)
                if [[ ",$opts," == *,ro,* ]]; then
                    echo "dsh-workspace: '$SRC' is read-only here; run 'dsh-workspace apply $argc_name' on the host" >&2
                    exit 1
                fi

                rsync -a --delete "$WS/" "$SRC/"
                echo "applied '$WS' -> '$SRC'"
            }

            # @cmd Delete the checkout without applying.
            # @arg name Checkout name
            function drop {
                resolve "$argc_name"
                rm -rf "$WS"
                echo "dropped '$argc_name'"
            }

            # @cmd List configured checkouts.
            function list {
                if [ -n "$checkouts" ]; then
                    cut -f1 <<<"$checkouts"
                fi
            }

            eval "$(${lib.getExe pkgs.argc} --argc-eval "$0" "$@")"
          '';
    in
    {
      options.deepseek-harness = {
        enable = lib.mkEnableOption "DeepSeek Harness (dsh) web UI, isolated in a NixOS container";

        package = mkOption {
          type = types.package;
          default = pkgs.deepseek-harness;
          defaultText = lib.literalExpression "pkgs.deepseek-harness";
          description = "The dsh package to run inside the container.";
        };

        port = mkOption {
          type = types.port;
          default = 3080;
          description = ''
            Loopback port the dsh web server binds. dsh refuses to bind anything
            but 127.0.0.1, so the container shares the host network namespace and
            the host reverse proxy reaches it on this port.
          '';
        };

        trustedHost = mkOption {
          type = types.str;
          default = "dsh.asmussen.tech";
          description = ''
            Authority the /api browser-trust fence accepts in addition to
            loopback. The reverse proxy forwards this Host, so it must be
            declared or every proxied /api request is refused.
          '';
        };

        stateDir = mkOption {
          type = types.path;
          default = "/var/lib/dsh";
          description = ''
            DSH_HOME inside the container: profiles, storages, UI-configured
            provider credentials, and the workspaces/ tree holding active
            checkouts. Bind-mounted from the host so it survives container
            rebuilds (persist this path on impermanent hosts).
          '';
        };

        uid = mkOption {
          type = types.int;
          default = 985;
          description = ''
            Pinned uid of the container-only dsh account. Deliberately distinct
            from any host user: the state dir is owned by this id and must stay
            stable across rebuilds or the persisted state is orphaned.
          '';
        };

        gid = mkOption {
          type = types.int;
          default = 982;
          description = "Pinned gid of the in-container dsh group.";
        };

        checkouts = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                source = mkOption {
                  type = types.path;
                  description = "Absolute path of the directory on the host.";
                };
              };
            }
          );
          default = { };
          example = lib.literalExpression ''
            {
              "/projects".source = "/home/bastian/Projects";
            }
          '';
          description = ''
            Host directories dsh may work on, keyed by the read-only path they
            are mounted at inside the container. Nothing writes to the source
            directly: dsh-workspace open mirrors it into a writable checkout
            under stateDir/workspaces where arbitrary agent commands run freely,
            dsh-workspace diff presents the result, and dsh-workspace apply
            promotes it back on the host. Checkout names derive from the mount
            path.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # Pause the host container to free the shared GPU during games.
        gamemode.pauseUnits = [ "container@dsh.service" ];

        assertions = [
          {
            assertion = lib.length checkoutNames == lib.length (lib.unique checkoutNames);
            message = "deepseek-harness: checkout mount paths collide after sanitisation (${lib.concatStringsSep ", " checkoutNames})";
          }
        ];

        containers.dsh = {
          autoStart = true;

          # Share the host network so the loopback proxy can reach dsh.
          bindMounts = {
            ${cfg.stateDir} = {
              hostPath = cfg.stateDir;
              isReadOnly = false;
            };
          }
          // lib.mapAttrs (_: checkout: {
            hostPath = toString checkout.source;
            isReadOnly = true;
          }) cfg.checkouts;

          config = {
            system.stateVersion = "26.05";

            users = {
              users.dsh = {
                isSystemUser = true;
                group = "dsh";
                inherit (cfg) uid;
                home = cfg.stateDir;
              };

              groups.dsh.gid = cfg.gid;
            };

            environment.systemPackages = [ dshWorkspace ];

            # Link /bin/bash for terminal-bash and persist the agent work
            # directory.
            systemd.tmpfiles.rules = [
              "L+ /bin/bash - - - - ${lib.getExe pkgs.bashInteractive}"
              "d ${cfg.stateDir}/work 0700 dsh dsh -"
            ];

            systemd.services.dsh = {
              description = "DeepSeek Harness web UI";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              environment = {
                DSH_HOME = cfg.stateDir;

                # The minimal preset reads DSH_CWD for the bash tool's cwd.
                DSH_CWD = "${cfg.stateDir}/work";
              };

              # Provide bash and a full userland for dsh's `bash -c` commands.
              path = with pkgs; [
                bashInteractive
                coreutils
                findutils
                gnugrep
                gnused
                gawk
                diffutils
                which
                file
                less
                gnutar
                gzip
                xz
                zip
                unzip
                ripgrep
                fd
                jq
                tree
                curl
                wget
                git
                openssh
                procps
                psmisc
                python3
                nodejs_22
                gcc
                gnumake
              ];

              serviceConfig = {
                ExecStart = "${lib.getExe cfg.package} web --no-open --port ${toString cfg.port} --trusted-host ${cfg.trustedHost}";
                User = "dsh";
                Group = "dsh";
                Restart = "on-failure";
                RestartSec = 5;

                # Set the harness cwd to the writable workspace instead of `/`.
                WorkingDirectory = "${cfg.stateDir}/work";
              };
            };
          };
        };

        # Use matching pinned host and container ids; preStart needs the host
        # user.
        users = {
          users.dsh = {
            isSystemUser = true;
            group = "dsh";
            inherit (cfg) uid;
          };

          groups.dsh.gid = cfg.gid;
        };

        # Install dsh-workspace on the host for applying reviewed checkouts.
        environment.systemPackages = [ dshWorkspace ];

        # Create the state directory before nspawn mounts it.
        systemd.services."container@dsh".preStart = ''
          install -d -m 0700 -o dsh -g dsh '${cfg.stateDir}'
        '';
      };
    };
}
