{
  flake.homeModules.ohMyPosh = {config, ...}: {
    programs.oh-my-posh = {
      enable = true;

      enableZshIntegration = config.programs.zsh.enable;
      settings = {
        version = 2;
        final_space = true;
        console_title_template = "{{ .Shell }} in {{ .Folder }}";
        blocks = [
          {
            type = "prompt";
            alignment = "left";
            newline = true;
            segments = [
              {
                type = "path";
                style = "plain";
                foreground = "blue";
                background = "transparent";
                template = "{{ .Path }}";
                properties.style = "full";
              }
              {
                type = "git";
                style = "plain";
                foreground = "p:grey";
                background = "transparent";
                template = "{{ if .HEAD }} {{ .HEAD }}{{ if or (.Working.Changed) (.Staging.Changed) }}*{{ end }}{{ if gt .Behind 0 }} <cyan>⇣</>{{ end }}{{ if gt .Ahead 0 }} <cyan>⇡</>{{ end }}{{ end }}";
                properties = {
                  branch_icon = "";
                  commit_icon = "@";
                  fetch_status = true;
                };
              }
              {
                type = "text";
                style = "plain";
                foreground = "p:grey";
                background = "transparent";
                template = ''
                  {{- $nix := env "IN_NIX_SHELL" -}}
                  {{- $box := env "CONTAINER_ID" -}}
                  {{- if or $nix $box }} ({{ end -}}
                  {{- if and $nix $box -}}
                    {{ if eq $nix "pure" }}<green>nix-shell</>{{ else }}nix-shell{{ end }} in {{ $box }}
                  {{- else if $nix -}}
                    in {{ if eq $nix "pure" }}<green>nix-shell</>{{ else }}nix-shell{{ end }}
                  {{- else if $box -}}
                    in {{ $box }}
                  {{- end -}}
                  {{- if or $nix $box }}){{ end -}}
                '';
              }
              {
                type = "session";
                style = "plain";
                foreground = "red";
                background = "transparent";
                template = "{{ if .SSHSession }}  {{ end }}";
              }
            ];
          }
          {
            type = "rprompt";
            overflow = "hidden";
            segments = [
              {
                type = "executiontime";
                style = "plain";
                foreground = "yellow";
                background = "transparent";
                template = "{{ .FormattedMs }}";
                properties = {
                  threshold = 5000;
                  style = "roundrock";
                };
              }
            ];
          }
          {
            type = "prompt";
            alignment = "left";
            newline = true;
            segments = [
              {
                type = "text";
                style = "plain";
                foreground_templates = [
                  "{{if gt .Code 0}}red{{end}}"
                  "{{if eq .Code 0}}magenta{{end}}"
                ];

                background = "transparent";
                template = "❯";
              }
            ];
          }
        ];

        transient_prompt = {
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}magenta{{end}}"
          ];

          background = "transparent";
          template = "❯ ";
        };

        secondary_prompt = {
          foreground = "magenta";
          background = "transparent";
          template = "❯❯ ";
        };

        palette.grey = "#6c6c6c";
      };
    };
  };
}
