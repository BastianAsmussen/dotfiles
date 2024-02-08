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
	starship

stow --adopt .
