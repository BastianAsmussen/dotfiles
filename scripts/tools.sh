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
  tokei \
  discord

# Install sccache.
cargo install sccache

