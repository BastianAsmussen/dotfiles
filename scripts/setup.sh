#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install required tools.
sudo pacman -S --noconfirm \
  git \
  stow

# Install dependencies.
./scripts/yay.sh
./scripts/gnome.sh
./scripts/terminal.sh
./scripts/tmux.sh
./scripts/neovim.sh
./scripts/toolchain.sh
./scripts/docker.sh

# Install additional tools.
./scripts/extra.sh

stow --adopt .

