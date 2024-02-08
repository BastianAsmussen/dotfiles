#!/bin/bash

# Sync package repos.
sudo pacman -Syy

# Install required tools.
sudo pacman -S --noconfirm \
	git \
	stow \
	zsh \
	neovim \
	starship

stow --adopt .
