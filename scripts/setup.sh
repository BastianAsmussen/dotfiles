#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install required tools.
sudo pacman -S --noconfirm \
  git \
  stow \
  ripgrep \
  ttf-jetbrains-mono-nerd \
  neovim \
  lldb \
  zsh \
  starship \
  alacritty \
  curl \
  zoxide \
  fzf \
  tmux

# Install tmux plugin manager.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Rust toolchain.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer

# Install additional tools.
./scripts/tools.sh

stow --adopt .

