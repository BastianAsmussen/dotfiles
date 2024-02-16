#!/bin/bash

# Install hyprland.
sudo pacman -S --noconfirm \
  sddm \
  xorg-xwayland \
  hyprland

# Enable SDDM.
sudo systemctl enable sddm.service

