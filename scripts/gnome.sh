#!/bin/bash

# Install Gnome.
sudo pacman -S --noconfirm \
  gnome \
  gdm

# Enable GDM.
sudo systemctl enable gdm

