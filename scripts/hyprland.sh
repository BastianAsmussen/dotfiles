#!/bin/bash

# Install hyprland.
sudo pacman -S --noconfirm \
  sddm \
  hyprland \
  swaylock \
  xorg-xwayland

# Enable SDDM.
sudo systemctl enable sddm.service

