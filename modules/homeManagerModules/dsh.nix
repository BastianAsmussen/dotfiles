{ self, ... }:
{
  flake.homeModules.dsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;
      inherit (config.home) homeDirectory;

      cfg = config.dsh;
      workspace = "${homeDirectory}/${cfg.workspace}";

      patch =
        pkgs.writeText "dsh.patch.yml"
          # yaml
          ''
            - id: sandbox-policy
              name: '@deepseek-ai/dsh-sandbox-policy'
              config:
                mode: !!js process.env.DSH_PERMISSION_MODE ?? 'workspace-write'
                workspaceRoot: !!js process.cwd()
                additionalWritableRoots: ${builtins.toJSON cfg.writableRoots}

            - id: spill-local
              name: '@deepseek-ai/dsh-spill-local'
              config:
                root: ${homeDirectory}/.dsh/spill
          '';

      dshUp = pkgs.writeShellApplication {
        name = "dsh-up";
        runtimeInputs = with pkgs; [ gnused ];
        text = ''
          systemctl --user start dsh.service

          for _ in $(seq 60); do
            url=$(journalctl --user --unit=dsh.service -I --output=cat \
              | sed -n 's/^dsh web: \(http[^[:space:]]*\).*/\1/p;T;q')
            if [[ -n $url ]]; then
              echo "$url"
              exit 0
            fi
            if ! systemctl --user is-active --quiet dsh.service; then
              journalctl --user --unit=dsh.service --lines=30 --no-pager
              exit 1
            fi
            sleep 1
          done

          echo "dsh-up: no URL after 60 s, see dsh-logs" >&2
          exit 1
        '';
      };
    in
    {
      options.dsh = {
        enable = lib.mkEnableOption "the DeepSeek Harness web UI as a manually started user service" // {
          default = true;
        };

        package = mkOption {
          description = "The dsh package to run.";
          type = types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
          defaultText = lib.literalExpression "self.packages.\${system}.dsh";
        };

        port = mkOption {
          description = "Loopback port the web UI listens on.";
          type = types.port;
          default = 3080;
        };

        workspace = mkOption {
          description = "Sandbox workspace root and service working directory, relative to the home directory.";
          type = types.str;
          default = ".local/share/dsh/workspace";
        };

        writableRoots = mkOption {
          description = "Real directories agents may write under besides the workspace, each also symlinked into it by name.";
          type = types.listOf types.str;
          default = [
            "${homeDirectory}/dotfiles"
            "${homeDirectory}/Projects"
          ];
        };
      };

      config = lib.mkIf cfg.enable {
        home = {
          packages = [
            cfg.package
            dshUp
          ];

          shellAliases = {
            dsh-down = "systemctl --user stop dsh.service";
            dsh-status = "systemctl --user status dsh.service";
            dsh-logs = "journalctl --user --unit=dsh.service --follow";
          };
        };

        persistence.directoriesWithMode = {
          ".dsh" = "0700";
          ".agents" = "0700";
          ${cfg.workspace} = "0700";
        };

        systemd.user = {
          tmpfiles.rules = [
            "d ${workspace} 0700 - - -"
          ]
          ++ map (root: "L+ ${workspace}/${baseNameOf root} - - - - ${root}") cfg.writableRoots;

          services.dsh = {
            Unit.Description = "DeepSeek Harness web UI";

            Service = {
              ExecStart = lib.concatStringsSep " " [
                (lib.getExe cfg.package)
                "--patch ${patch}"
                "--profile web"
                "--no-open"
                "--host 127.0.0.1"
                "--port ${toString cfg.port}"
              ];

              WorkingDirectory = workspace;
              # dsh refuses a group- or world-readable .credentials.yaml.
              UMask = "0077";
              Environment = [ "DSH_TELEMETRY_DISABLED=1" ];
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
        };
      };
    };
}
