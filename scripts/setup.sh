#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install required tools.
sudo pacman -S --noconfirm \
  git \
  stow

# Install tools.
./scripts/hyprland.sh
./scripts/terminal.sh
./scripts/tmux.sh
./scripts/neovim.sh
./scripts/toolchain.sh

# Install additional tools.
./scripts/extra.sh

stow --adopt .

