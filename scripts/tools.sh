#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install additional tools.
sudo pacman -S --noconfirm \
  grex \
  bat \
  eza \
  tokei

