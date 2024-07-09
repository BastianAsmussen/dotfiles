# dotfiles

This is a repository for my NixOS configuration.

## Installation Guide

1. Clone the Git repository.
```sh
nix run --experimental-features "nix-command flakes" run nixpkgs#git -- \
  git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles && \
  cd ~/dotfiles && \
  git checkout nixos
```

2. Set up the disk configuration, e.g. for `limitless`.
```sh
echo "password123" > /tmp/secret.key

sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko ~/dotfiles/hosts/limitless/disko-config.nix
```

3. Install NixOS with the given profile, e.g. `limitless`.
```sh
sudo nixos-install --flake ~/dotfiles#limitless
```

