#!/bin/bash

# Install required tools.
sudo pacman -Syy
sudo pacman -S --noconfirm $(cat ./scripts/dependencies.txt)

# Set up symlinks.
stow --adopt .

