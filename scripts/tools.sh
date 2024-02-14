#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install additional tools.
sudo pacman -S --noconfirm \
  bat \
  eza \
  ripgrep \
  gitui \
  grex \
  tokei

# Install sccache.
cargo install --locked sccache

