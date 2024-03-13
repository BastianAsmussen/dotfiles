#!/bin/bash

# Install Tmux.
sudo pacman -S --noconfirm \
  tmux \
  xclip # For copy-paste support.

# Install Tmux Plugin Manager.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

