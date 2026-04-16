{
  flake.homeModules.zsh = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs = {
      command-not-found.enable = false;
      nix-your-shell = {
        enable = true;

        enableZshIntegration = true;
      };

      zsh = {
        enable = true;

        autocd = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          append = true;
          ignoreAllDups = true;
          path = "${config.xdg.dataHome}/zsh/history";
          size = 16 * 1024;
        };

        historySubstringSearch.enable = true;

        defaultKeymap = "emacs";
        initContent =
          # sh
          ''
            # Keybindings.
            bindkey '^f' autosuggest-accept

            bindkey '^[[1;5C' emacs-forward-word
            bindkey '^[[1;5D' emacs-backward-word
            bindkey '^[[3~' delete-char

            bindkey '^p' history-search-backward
            bindkey '^n' history-search-forward

            # Open buffer line in editor.
            autoload -Uz edit-command-line
            zle -N edit-command-line
            bindkey '^x^e' edit-command-line

            # Expands history expressions like !! or !$ when you press space.
            bindkey ' ' magic-space

            # Project environment loader hooks.
            autoload -Uz add-zsh-hook

            function auto_venv() {
              # If already in a virtualenv, do nothing.
              if [[ -n "$VIRTUAL_ENV" && "$PWD" != *"''${VIRTUAL_ENV:h}"* ]]; then
                deactivate

                return
              fi

              [[ -n "$VIRTUAL_ENV" ]] && return

              local dir="$PWD"
              while [[ "$dir" != "/" ]]; do
                if [[ -f "$dir/.venv/bin/activate" ]]; then
                  source "$dir/.venv/bin/activate"
                  return
                fi

                dir="''${dir:h}"
              done
            }

            function auto_nvm() {
              [[ -f .nvmrc ]] && nvm use
            }

            add-zsh-hook chpwd auto_venv
            add-zsh-hook chpwd auto_nvm

            # Enable zmv module.
            autoload -Uz zmv

            # Bookmarked directories.
            hash -d personal=~/Projects/Personal
            hash -d work=~/Projects/Work
            hash -d school=~/Projects/School
            hash -d cfg=~/dotfiles
            hash -d sec=~/nix-secrets
            hash -d dl=~/Downloads

            # Clear screen but keep current command buffer.
            function clear-screen-and-scrollback() {
              echoti civis >"$TTY"
              printf '%b' '\e[H\e[2J\e[3J' >"$TTY"

              echoti cnorm >"$TTY"
              zle redisplay
            }

            zle -N clear-screen-and-scrollback
            bindkey '^xl' clear-screen-and-scrollback

            # Just type the filename to open it with the associated program.
            alias -s md=bat
            alias -s txt=bat
            alias -s log=bat
            alias -s json=jless
            alias -s go='$$EDITOR'
            alias -s rs='$EDITOR'
            alias -s py='$EDITOR'
            alias -s js='$EDITOR'
            alias -s ts='$EDITOR'

            # Match any case.
            zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

            ${lib.optionalString config.programs.nix-index.enable
              # sh
              ''
                # `command-not-found` replacement.
                source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
              ''}

            # Previews.
            zstyle ':completion:*:git-checkout:*' sort false
            zstyle ':completion:*:descriptions' format '[%d]'
            zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
            zstyle ':completion:*' menu no

            zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
            zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

            # Extra completions.
            source <(${lib.getExe pkgs.todo} completion zsh)
          '';

        shellAliases = {
          # Make sudo use aliases.
          sudo = "sudo ";

          c = "clear";
          cp = "cp --recursive";
          rm = "rm --recursive";
          mkdir = "mkdir --parents";

          # Copy and link with patterns.
          zcp = "zmv -C";
          zln = "zmv -L";

          myip = "curl --silent --write-out '\n' https://ifconfig.me/";
          system-size = "nix path-info -Sh /run/current-system | awk '{ print $2, $3 }'";
        };

        shellGlobalAliases = {
          # Pipe to (rip)grep.
          G = "| grep";
          RG = "| rg";

          # Pipe to jq.
          J = "| jq";

          # Redirect stdout to /dev/null.
          NO = ">/dev/null";

          # Redirect stderr to /dev/null.
          NE = "2>/dev/null";

          # Redirect both stdout and stderr to /dev/null.
          NUL = ">/dev/null 2>&1";

          # Copy output to clipboard.
          C = "| wl-copy";
        };

        oh-my-zsh = {
          enable = true;

          extraConfig =
            # sh
            ''
              zstyle ':completion:*:*:docker:*' option-stacking yes
              zstyle ':completion:*:*:docker-*:*' option-stacking yes
            '';

          plugins = [
            "archlinux"
            "docker"
            "docker-compose"
            "dotnet"
            "eza"
            "git"
            "golang"
            "kubectl"
            "kubectx"
            "pass"
            "rust"
            "sudo"
          ];
        };

        plugins = [
          {
            name = "fzf-tab";
            src = pkgs.zsh-fzf-tab;
            file = "share/fzf-tab/fzf-tab.plugin.zsh";
          }
        ];
      };
    };
  };
}
