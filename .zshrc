# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/bastian/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Initialize zoxide.
eval "$(zoxide init --cmd cd zsh)"

# Initialize Starship prompt.
eval "$(starship init zsh)"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Load zinit modules.
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# Source other auto-completions.
source <(kubectl completion zsh)

# Set locale.
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Add direcftories to the PATH.
export PATH="$HOME/.cargo/bin:$PATH" # Cargo.
export PATH="/usr/local/bin:/usr/bin:$PATH" # Local binaries.

# Add aliases.
alias vim=nvim
alias cat="bat --paging=never"
alias ls="eza -1"

