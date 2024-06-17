# Set the directory we want to store Zinit and plugins in.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet.
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit.
source "$ZINIT_HOME/zinit.zsh"

# Add in Zsh plugins.
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light nix-community/nix-zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets.
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions.
autoload -Uz compinit && compinit

zinit cdreplay -q

# Initialize prompt.
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/theme.toml)"

# Set up keybindings.
bindkey -e # Use Emacs bindings.
bindkey '^[[1;5C' emacs-forward-word
bindkey '^[[1;5D' emacs-backward-word
bindkey '^[[3~' delete-char

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Enable history.
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups

# Completion styling.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'cat $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Enable auto cd.
setopt auto_cd

# Aliases.
alias pwd='pwd && pwd | xclip -sel clipboard'

## Fix typos.
alias pdw='pwd'
alias cd..='cd ..'

alias vim='nvim'
alias vi='vim'

alias ls='ls --color'
alias c='clear'

alias neofetch='fastfetch'

alias cp='cp -r'
alias rm='rm -r'

# Shell integrations.
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

export GPG_TTY=$(tty)

# Ripgrep config.
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Set fzf colors.
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
	--color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
	--color=fg+:#c0caf5,bg+:#1a1b26,hl+:#7dcfff
	--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
	--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a'
