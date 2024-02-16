#!/bin/bash

# Install the dependencies.
sudo pacman -S --noconfirm \
  curl \
  lldb

# Install Rust toolchain.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer

# Install sccache.
cargo install sccache

