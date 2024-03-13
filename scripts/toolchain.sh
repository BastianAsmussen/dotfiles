#!/bin/bash

# Install the dependencies.
sudo pacman -S --noconfirm \
  curl \
  lldb

# Install Rust toolchain.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source the environment.
source $HOME/.cargo/env

rustup component add rust-analyzer

