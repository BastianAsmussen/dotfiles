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
  zsh \
  starship \
  kitty \
  curl

# Install Rust toolchain.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer

stow --adopt .
