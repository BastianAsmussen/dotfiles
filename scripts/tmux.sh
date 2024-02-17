#!/bin/bash

# Install Tmux.
sudo pacman -S --noconfirm \
  tmux

# Install Tmux Plugin Manager.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

