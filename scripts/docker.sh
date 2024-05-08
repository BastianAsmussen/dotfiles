#!/bin/bash

# Install Docker CLI.
sudo pacman -S --noconfirm \
  docker \
  docker-compose \
  docker-buildx

# Set up symlinks.
sudo ln -sf /usr/bin/docker /usr/local/bin/docker
sudo ln -sf /usr/bin/docker /usr/local/bin/com.docker.cli

# Install Docker Desktop.
yay -S docker-desktop

