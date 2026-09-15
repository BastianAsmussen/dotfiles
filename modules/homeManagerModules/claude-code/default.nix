{
  flake.homeModules.claudeCode =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) getExe' genAttrs getExe;

      proxyHook = {
        type = "command";
        command = "${getExe' pkgs.caveman-cli "caveman-proxy"} native-hook claude --adapter '${pkgs.caveman-cli}/lib/caveman-cli/dist/native-hook-fast.js'";
        timeout = 30;
      };

      proxyHooks = genAttrs [
        "SessionStart"
        "UserPromptSubmit"
        "PreToolUse"
        "PostToolUse"
        "PostToolUseFailure"
        "PreCompact"
        "SubagentStart"
        "SubagentStop"
        "Stop"
        "SessionEnd"
      ] (_: [ { hooks = [ proxyHook ]; } ]);
    in
    {
      programs.claude-code = {
        enable = true;
        context = ./CLAUDE.md;
        skills = ./skills;
        outputStyles.tolerable = ./output-styles/tolerable.md;

        settings = {
          outputStyle = "Tolerable";
          model = "opus";
          effortLevel = "xhigh";
          theme = "dark-ansi";
          timeFormat = "24-hour";

          autoCompactEnabled = true;
          autoModeDuringPlan = false;
          awaySummaryEnabled = false;
          enableWorkflows = true;
          promptSuggestionEnabled = false;
          remoteControlAtStartup = false;
          skipWorkflowUsageWarning = true;

          env = {
            ANTHROPIC_BASE_URL = "http://127.0.0.1:8787/w/claude";
            CLAUDE_CODE_SCROLL_SPEED = "8";
            ENABLE_TOOL_SEARCH = "auto";
            _CLAUDE_CODE_ASSUME_FIRST_PARTY_BASE_URL = "1";
          };

          modelSettings =
            genAttrs
              [
                "claude-opus-5"
                "claude-sonnet-5"
                "claude-sonnet-4-6"
              ]
              (_: {
                effortLevel = "xhigh";
              });

          hooks = proxyHooks // {
            PreToolUse = proxyHooks.PreToolUse ++ [
              {
                hooks = [
                  {
                    type = "command";
                    command = "${getExe pkgs.caveman-cli} shrink-hook";
                    timeout = 30;
                  }
                ];
              }
            ];
          };

          enabledPlugins = {
            "rust-analyzer-lsp@claude-plugins-official" = true;
            "typescript-lsp@claude-plugins-official" = true;
            "skill-creator@claude-plugins-official" = true;
            "frontend-design@claude-plugins-official" = true;
          };

        };

        lspServers = {
          rust = {
            command = "${getExe pkgs.rust-analyzer}";
            extensionToLanguage.".rs" = "rust";
          };

          go = {
            args = [ "serve" ];
            command = "${getExe pkgs.gopls}";
            extensionToLanguage.".go" = "go";
          };

          typescript = {
            args = [ "--stdio" ];
            command = "${getExe pkgs.typescript-language-server}";
            extensionToLanguage = {
              ".js" = "javascript";
              ".jsx" = "javascriptreact";
              ".ts" = "typescript";
              ".tsx" = "typescriptreact";
            };
          };
        };

        mcpServers.caveman = {
          type = "stdio";
          command = getExe' pkgs.caveman-cli "caveman-mcp";
        };

        package =
          (pkgs.writeShellScriptBin "claude" ''
            export PATH="${
              lib.strings.makeSearchPathOutput "bin" "bin" [
                pkgs.caveman-cli
                pkgs.claude-code
              ]
            }:$PATH"

            exec ${getExe pkgs.caveman-cli} claude "$@"
          '').overrideAttrs
            (_: {
              inherit (pkgs.claude-code) version;
            });
      };

      persistence = {
        files = [ ".claude.json" ];
        directoriesWithMode = {
          ".caveman" = "0700";
          ".claude" = "0700";
        };
      };
    };
}
