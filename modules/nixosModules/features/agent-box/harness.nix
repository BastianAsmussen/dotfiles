# Runs a long-running agent harness inside the agent box (see guest.nix).
{
  flake.nixosModules.agentBoxGuestHarness =
    { config, lib, ... }:
    let
      inherit (lib)
        elem
        mkEnableOption
        mkIf
        mkOption
        optional
        types
        ;

      cfg = config.agentBoxGuest;
      inherit (cfg) harness;
    in
    {
      options.agentBoxGuest.harness = {
        enable = mkEnableOption "a long-running agent harness";

        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = "Package providing the harness binary, added to the service's PATH.";
        };

        command = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "myharness serve --workspace \"$AGENT_WORKSPACE\"";
          description = "Command the harness service runs. Required when enabled.";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Extra environment variables for the harness, merged over the contract.";
        };

        restart = mkOption {
          type = types.str;
          default = "always";
          description = "systemd restart policy of the harness service.";
        };

        extraServiceConfig = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Extra systemd service settings for the harness.";
        };
      };

      config = mkIf harness.enable {
        assertions = [
          {
            assertion = harness.command != null;
            message = "agentBoxGuest.harness.command must be set when the harness is enabled.";
          }
          {
            assertion = !cfg.llm.enable || elem cfg.llm.apiKeyEnv cfg.credentials;
            message = "agentBoxGuest.llm.apiKeyEnv (${cfg.llm.apiKeyEnv}) is not among the credentials the host passes in.";
          }
        ];

        systemd.services.agent-harness = {
          description = "Agent harness";
          wantedBy = [ "multi-user.target" ];
          after = [ "agent-credentials.service" ];
          requires = [ "agent-credentials.service" ];

          path = optional (harness.package != null) harness.package;
          environment = cfg.contract // harness.environment;

          serviceConfig = {
            User = cfg.user;
            WorkingDirectory = cfg.contract.AGENT_WORKSPACE;
            ExecStart = harness.command;
            Restart = harness.restart;
            RestartSec = "5s";
            UMask = "0077";
          }
          // harness.extraServiceConfig;
        };
      };
    };
}
