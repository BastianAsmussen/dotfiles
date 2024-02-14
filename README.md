# dotfiles

This is a repository for the dotfiles of my system.

## Prerequisites

### Git

1. Install Git on the system.
```
sudo pacman -S git
```

### SSH

1. Create a new SSH key at `~/.ssh/github`:
```sh
ssh-keygen -t ed25519 -C "<value>"
```

2. Add a new key to [GitHub](https://github.com/settings/ssh/new) preferrably with the name `<value>`:
```sh
cat ~/.ssh/github.pub
```

3. Create an SSH config:
```sh
cat > ~/.ssh/config <<EOF
Host GitHub
  Hostname github.com
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
  User git
EOF
```

## Optional

1. Clean out old Neovim config.
```sh
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
```

## Setup

1. Clone the repository:
```sh
git clone GitHub:BastianAsmussen/dotfiles.git ~/dotfiles
```

2. Enter the repository:
```sh
cd ~/dotfiles
```

2. Run the [setup](scripts/setup.sh) script to set every thing else up:
```sh
./scripts/setup.sh
```

### Tmux

#### Install Plugins

1. Start a Tmux session:
```sh
tmux
```

2. Install the plugins:
```sh
<C-Space>I
```

### Neovim

#### Install Plugins

1. Open Neovim:
```sh
nvim
```

