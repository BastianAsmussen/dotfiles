#!/bin/bash

pacman -S --needed \
  git \
  base-devel

# Install Yay.
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si

# Cleanup.
cd ..
rm -rf yay-bin

