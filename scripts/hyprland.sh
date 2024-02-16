#!/bin/bash

# Install hyprland.
sudo pacman -S --noconfirm \
  sddm \
  hyprland \
  dolphin \
  swaylock \
  waybar \
  xorg-xwayland

# Enable SDDM.
sudo systemctl enable sddm.service

