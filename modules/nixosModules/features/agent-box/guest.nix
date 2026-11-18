# NixOS configuration inside the agent box container (see host.nix).
{ inputs, self, ... }:
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
        genAttrs
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.agentBoxGuest;

      user = "agent";
      uid = 1000;
      home = "/home/${user}";

      credentialDir = "/run/agent-credentials";
      stateDir = "/var/lib/agent-box";
      gatewayToken = "${stateDir}/gateway-token";
      searxEnv = "${stateDir}/searx.env";

      openssl = lib.getExe pkgs.openssl;
    in
    {
      imports = [
        self.nixosModules.dns
        inputs.home-manager.nixosModules.home-manager
      ];

      options.agentBoxGuest = {
        credentials = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Names of the credentials the host passes in. Each is exported to OpenClaw as an environment variable of the same name.";
        };

        llm = {
          baseUrl = mkOption {
            type = types.str;
            default = "https://api.cheaperinference.com/v1";
            description = "Base URL of the OpenAI-compatible endpoint OpenClaw talks to.";
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

        searxPort = mkOption {
          type = types.port;
          default = 8888;
          description = "Loopback port SearXNG listens on.";
        };

        runtimePlugins = mkOption {
          type = types.listOf types.str;
          default = [ "searxng" ];
          description = "OpenClaw runtime plugin ids that Nix packages and loads.";
        };

        packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages on the agent's PATH.";
        };

        openclaw.enable = mkEnableOption "the OpenClaw gateway" // {
          default = true;
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.openclaw.enable -> lib.elem cfg.llm.apiKeyEnv cfg.credentials;
            message = "agentBoxGuest.llm.apiKeyEnv (${cfg.llm.apiKeyEnv}) is not among the credentials the host passes in.";
          }
        ];

        system.stateVersion = "26.05";

        # The host's stub resolver is unreachable from the private network.
        networking.useHostResolvConf = false;

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        users = {
          users.${user} = {
            inherit uid home;

            isNormalUser = true;
            group = user;
            description = "Autonomous agent";

            # Keep the gateway running without a login session.
            linger = true;
          };

          # Matches the host user, so the idmapped workspace stays theirs.
          groups.${user}.gid = uid;
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
          before = [
            "searx-init.service"
            "user@${toString uid}.service"
            "home-manager-${user}.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ImportCredential = cfg.credentials;
            UMask = "0077";
          };

          script = ''
            install -d -m 0750 -g ${user} ${credentialDir}
            ${concatMapStrings (name: ''
              install -m 0440 -g ${user} "$CREDENTIALS_DIRECTORY"/${escapeShellArg name} ${credentialDir}/${escapeShellArg name}
            '') cfg.credentials}

            install -d -m 0755 ${stateDir}
            if [ ! -s ${gatewayToken} ]; then
              ${openssl} rand -hex 32 > ${gatewayToken}
            fi
            chown ${user}:${user} ${gatewayToken}
            chmod 0400 ${gatewayToken}

            if [ ! -s ${searxEnv} ]; then
              printf 'SEARX_SECRET_KEY=%s\n' "$(${openssl} rand -hex 32)" > ${searxEnv}
            fi
          '';
        };

        systemd.services.searx-init = {
          after = [ "agent-credentials.service" ];
          requires = [ "agent-credentials.service" ];
        };

        services.searx = {
          enable = true;
          environmentFile = searxEnv;
          settings = {
            server = {
              bind_address = "127.0.0.1";
              port = cfg.searxPort;
              secret_key = "$SEARX_SECRET_KEY";
            };

            # OpenClaw reads the JSON API.
            search.formats = [
              "html"
              "json"
            ];
          };
        };

        home-manager = mkIf cfg.openclaw.enable {
          useGlobalPkgs = true;
          useUserPackages = true;

          users.${user} = {
            imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

            home.stateVersion = "26.05";
            systemd.user = {
              startServices = "sd-switch";

              # nix-openclaw leaves the unit without an install target.
              services.openclaw-gateway.Install.WantedBy = [ "default.target" ];
            };

            programs.openclaw = {
              enable = true;
              inherit (cfg) runtimePlugins;

              # The shared host directory, so its memory and output stay visible.
              workspaceDir = "${home}/workspace";

              # Cameras and Sonos sit on a LAN the box cannot reach.
              excludeTools = [
                "camsnap"
                "sonoscli"
              ];

              # File paths are read when the gateway starts.
              environment = genAttrs cfg.credentials (name: "${credentialDir}/${name}") // {
                OPENCLAW_GATEWAY_TOKEN = gatewayToken;
              };

              config = {
                gateway = {
                  mode = "local";
                  auth.token = "\${OPENCLAW_GATEWAY_TOKEN}";
                };

                models = {
                  mode = "merge";
                  providers.llm = {
                    inherit (cfg.llm) baseUrl;

                    apiKey = "\${${cfg.llm.apiKeyEnv}}";
                    api = "openai-completions";
                    models = [
                      {
                        id = cfg.llm.model;
                        name = cfg.llm.model;
                        input = [ "text" ];
                        inherit (cfg.llm) contextWindow maxTokens;
                      }
                    ];
                  };
                };

                agents.defaults = {
                  model.primary = "llm/${cfg.llm.model}";

                  # The container is the sandbox, and it has no Docker.
                  sandbox.mode = "off";
                };

                tools.web.search.provider = "searxng";
                plugins.entries.searxng.config.webSearch.baseUrl = "http://127.0.0.1:${toString cfg.searxPort}";
              };
            };
          };
        };
      };
    };
}
