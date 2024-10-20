{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [./scripts];

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;

    history = {
      size = 16 * 1024;
      path = "${config.xdg.dataHome}/zsh/history";

      ignoreAllDups = true;
    };

    defaultKeymap = "emacs";

    initExtra = ''
      # Keybindings.
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
      source <(rustup completions zsh)
    '';

    shellAliases = {
      c = "clear";

      cp = "cp -r";
      rm = "rm -r";

      myip = "${lib.getExe pkgs.curl} ifconfig.me && echo ''";
    };

    oh-my-zsh = {
      enable = true;

      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "kubectl"
        "kubectx"
        "rust"
        "pass"
      ];
    };

    plugins = with pkgs; [
      {
        name = "zsh-syntax-highlighting";
        src = zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
      {
        name = "zsh-completions";
        src = zsh-completions;
        file = "share/zsh-completions/zsh-completions.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "fzf-tab";
        src = zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };
}
