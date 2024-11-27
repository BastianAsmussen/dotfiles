# dotfiles

This is a repository for the dotfiles of my system.

> [!CAUTION]
> This branch isn't actively updated or maintained at all! It simply exists as
> a kind of backup.  
> While things may continue to work, I won't guarantee that it will forever.

## Prerequisites

### Git

1. Install Git on the system.

```sh
sudo pacman -S git
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
git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles
```

2. Enter the repository:

```sh
cd ~/dotfiles
```

3. Switch branch:

```sh
git checkout old
```

4. Run the [install](scripts/install.sh) script to set every thing else up:

```sh
./scripts/install.sh
```

5. Install [oh-my-posh](https://ohmyposh.dev/) from the AUR.

```sh
yay -S oh-my-posh
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
