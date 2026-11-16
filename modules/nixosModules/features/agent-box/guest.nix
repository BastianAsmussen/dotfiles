# NixOS configuration inside the agent box container (see host.nix). It owns the
# harness contract: paths in the environment, credentials as files.
{ self, ... }:
{
  flake.nixosModules.agentBoxGuest =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatMapStrings
        escapeShellArg
        mkEnableOption
        mkIf
        mkOption
        optional
        optionalAttrs
        optionalString
        types
        ;

      cfg = config.agentBoxGuest;

      uid = 1000;
      home = "/home/${cfg.user}";

      credentialDir = "/run/agent-credentials";
      tokenFile = "${cfg.stateDir}/agent-token";
      stateSubdir = "${cfg.stateDir}/state";
      searxEnv = "${cfg.stateDir}/searx.env";

      openssl = lib.getExe pkgs.openssl;
    in
    {
      imports = [
        self.nixosModules.dns
        self.nixosModules.agentBoxGuestHarness
      ];

      options.agentBoxGuest = {
        user = mkOption {
          type = types.str;
          default = "agent";
          readOnly = true;
          description = "Container user the harness runs as. Fixed so the host's idmapped workspace keeps its ownership.";
        };

        stateDir = mkOption {
          type = types.str;
          default = "/var/lib/agent-box";
          description = "Root-owned directory for generated secrets. The harness gets a writable `state` subdirectory.";
        };

        credentials = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Names of the credentials the host passes in. Each is copied to `AGENT_CREDENTIALS_DIR`.";
        };

        llm = {
          enable = mkEnableOption "an OpenAI-compatible LLM endpoint" // {
            default = true;
          };

          baseUrl = mkOption {
            type = types.str;
            default = "https://api.cheaperinference.com/v1";
            description = "Base URL of the OpenAI-compatible endpoint the harness talks to.";
          };

          apiKeyEnv = mkOption {
            type = types.str;
            default = "LLM_API_KEY";
            description = "Credential holding the endpoint's API key.";
          };

          model = mkOption {
            type = types.str;
            default = "deepseek-v4-flash";
            description = "Model id to request from the endpoint.";
          };

          contextWindow = mkOption {
            type = types.ints.positive;
            default = 1048576;
            description = "Context window of the model, in tokens.";
          };

          maxTokens = mkOption {
            type = types.ints.positive;
            default = 32768;
            description = "Maximum output tokens per response.";
          };
        };

        searx = {
          enable = mkEnableOption "SearXNG for the harness's web search" // {
            default = true;
          };

          port = mkOption {
            type = types.port;
            default = 8888;
            description = "Loopback port SearXNG listens on.";
          };
        };

        packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages on the harness's PATH.";
        };

        contract = mkOption {
          type = types.attrsOf types.str;
          readOnly = true;
          description = "Environment handed to the harness. Values are paths, never secrets.";
          default = {
            AGENT_HOME = home;
            AGENT_WORKSPACE = "${home}/workspace";
            AGENT_STATE_DIR = stateSubdir;
            AGENT_CREDENTIALS_DIR = credentialDir;
            AGENT_TOKEN_FILE = tokenFile;
          }
          // optionalAttrs cfg.llm.enable {
            AGENT_LLM_BASE_URL = cfg.llm.baseUrl;
            AGENT_LLM_MODEL = cfg.llm.model;
            AGENT_LLM_API_KEY_FILE = "${credentialDir}/${cfg.llm.apiKeyEnv}";
            AGENT_LLM_CONTEXT_WINDOW = toString cfg.llm.contextWindow;
            AGENT_LLM_MAX_TOKENS = toString cfg.llm.maxTokens;
          }
          // optionalAttrs cfg.searx.enable {
            SEARXNG_URL = "http://127.0.0.1:${toString cfg.searx.port}";
          };
        };
      };

      config = {
        system.stateVersion = "26.05";

        # The host's stub resolver is unreachable from the private network.
        networking.useHostResolvConf = false;

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        # The container evaluates its own nixpkgs, so the host's config does not apply.
        nixpkgs.config.allowUnfree = true;

        users = {
          users.${cfg.user} = {
            inherit uid home;

            isNormalUser = true;
            group = cfg.user;
            description = "Autonomous agent";

            # Keep user services running without a login session.
            linger = true;
          };

          # Matches the host user, so the idmapped workspace stays theirs.
          groups.${cfg.user}.gid = uid;
        };

        environment.systemPackages =
          with pkgs;
          [
            curl
            fd
            git
            jq
            jujutsu
            just
            nodejs
            python3
            ripgrep
            tmux
          ]
          ++ cfg.packages;

        # Copy the host's credentials where the agent can read them.
        systemd.services.agent-credentials = {
          description = "Agent credentials and generated secrets";
          wantedBy = [ "multi-user.target" ];
          before = [ "user@${toString uid}.service" ] ++ optional cfg.searx.enable "searx-init.service";

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ImportCredential = cfg.credentials;
            UMask = "0077";
          };

          script = ''
            install -d -m 0750 -g ${cfg.user} ${credentialDir}
            ${concatMapStrings (name: ''
              install -m 0440 -g ${cfg.user} "$CREDENTIALS_DIRECTORY"/${escapeShellArg name} ${credentialDir}/${escapeShellArg name}
            '') cfg.credentials}

            install -d -m 0755 ${cfg.stateDir}
            install -d -m 0750 -o ${cfg.user} -g ${cfg.user} ${stateSubdir}

            if [ ! -s ${tokenFile} ]; then
              ${openssl} rand -hex 32 > ${tokenFile}
            fi
            chown ${cfg.user}:${cfg.user} ${tokenFile}
            chmod 0400 ${tokenFile}
            ${optionalString cfg.searx.enable ''
              if [ ! -s ${searxEnv} ]; then
                printf 'SEARX_SECRET_KEY=%s\n' "$(${openssl} rand -hex 32)" > ${searxEnv}
              fi
            ''}
          '';
        };

        systemd.services.searx-init = mkIf cfg.searx.enable {
          after = [ "agent-credentials.service" ];
          requires = [ "agent-credentials.service" ];
        };

        services.searx = mkIf cfg.searx.enable {
          enable = true;
          environmentFile = searxEnv;
          settings = {
            server = {
              bind_address = "127.0.0.1";
              port = cfg.searx.port;
              secret_key = "$SEARX_SECRET_KEY";
            };

            # Harnesses query the JSON API.
            search.formats = [
              "html"
              "json"
            ];
          };
        };
      };
    };
}
