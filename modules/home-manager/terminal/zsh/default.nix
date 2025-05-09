{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./nix-index.nix
    ./zoxide.nix
  ];

  programs.zsh = {
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

        # Match any case.
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

        # Previews.
        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu no

        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

        # Extra completions.
        source <(${lib.getExe pkgs.todo} completion zsh)

        # Automatic tmux session through SSH.
        if [[ $- =~ i ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_TTY" ]]; then
          ${lib.getExe pkgs.tmux} new -As ssh
        fi
      '';

    shellAliases = {
      # Make sudo use aliases.
      sudo = "sudo ";

      c = "clear";
      cp = "cp -r";
      rm = "rm -r";
      mkdir = "mkdir -p";

      myip = "curl -s ifconfig.me -w '\n'";
      system-size = "nix path-info -Sh /run/current-system | tail -1 | awk '{ print $2, $3 }'";
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
        "command-not-found"
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
}
