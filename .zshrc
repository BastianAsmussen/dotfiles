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
eval "$(zoxide init zsh)"

# Initialize Starship prompt.
eval "$(starship init zsh)"

# Add Cargo's bin directory to the PATH.
export PATH="$HOME/.cargo/bin:$PATH"

# Add aliases.
alias vim=nvim
alias cat="bat --paging=never"
alias ls="eza -1"

