#!/bin/bash

# Install hyprland.
sudo pacman -S --noconfirm \
  sddm \
  hyprland \
  dolphin \
  swaylock \
  waybar \
  wofi \
  xorg-xwayland

# Enable SDDM.
sudo systemctl enable sddm.service

