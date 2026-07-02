{ inputs, self, ... }:
{
  flake.homeModules.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      jsonFormat = pkgs.formats.json { };

      opencodeConfig = jsonFormat.generate "opencode.json" {
        "$schema" = "https://opencode.ai/config.json";

        instructions = [ "AGENTS.md" ];
        shell = lib.getExe pkgs.zsh;
        plugin = [
          "opencode-agent-memory"
          "opencode-background-agents"
          "opencode-command-inject"
          "opencode-direnv"
        ];

        provider.deepseek = {
          models = {
            deepseek-chat = { };
            deepseek-v4-pro = { };
          };

          options.apiKey = "{file:${config.sops.secrets."deepseek-api-key".path}}";
        };

        model = "deepseek/deepseek-v4-pro";
        small_model = "deepseek/deepseek-chat";
        permission = {
          edit = "allow";
          bash = "allow";
        };

        watcher.ignore = [
          "node_modules/**"
          ".direnv/**"
          ".terraform/**"
          "result/**"
        ];
      };

      agentMemoryConfig = jsonFormat.generate "agent-memory.json" {
        journal = {
          enabled = true;
          tags = [
            {
              name = "nix";
              description = "Nix/NixOS packaging, flake, and module system learnings";
            }
            {
              name = "dotfiles";
              description = "This dotfiles project — architecture and conventions";
            }
            {
              name = "opencode";
              description = "OpenCode tool, plugin, and agent configuration";
            }
            {
              name = "gotcha";
              description = "Non-obvious pitfalls and surprising behaviors";
            }
            {
              name = "linux";
              description = "Linux system administration and networking";
            }
          ];
        };
      };
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
      sops.secrets."deepseek-api-key".sopsFile = "${toString inputs.nix-secrets}/shared.yaml";

      home.packages = [ pkgs.opencode ];
      xdg.configFile =
        let
          mkConfigDir =
            subdir:
            builtins.listToAttrs (
              map (name: {
                name = "opencode/${subdir}/${name}";
                value.source = "${self}/modules/homeManagerModules/opencode/${subdir}/${name}";
              }) (builtins.attrNames (builtins.readDir "${self}/modules/homeManagerModules/opencode/${subdir}"))
            );
        in
        {
          "opencode/opencode.json".source = opencodeConfig;
          "opencode/agent-memory.json".source = agentMemoryConfig;
          "opencode/AGENTS.md".source = "${self}/modules/homeManagerModules/opencode/AGENTS.md";
        }
        // mkConfigDir "skills"
        // mkConfigDir "references";
    };
}
