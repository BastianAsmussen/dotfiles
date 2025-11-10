# dotfiles

This is a repository for my NixOS configurations.

## Table of Contents

- [Installation Guide](#installation-guide)

## Installation Guide

1. Get the source code.
   1. Enter a Nix shell with Git.

      ```sh
      nix-shell -p git fzf
      ```

   2. Clone the Git repository.

      ```sh
      git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles

      cd ~/dotfiles
      ```

   3. Or, as a one-liner.

      ```sh
      nix-shell -p git fzf --run "git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles && cd ~/dotfiles"
      ```

2. Choose a host.
    1. Choose a host.

        ```sh
        HOSTNAME=$(ls ./modules/nixosModules/hosts | fzf)
        ```
        
    2. Set manually, e.g. `lambda`.

        ```sh
        HOSTNAME="lambda"
        ```

3. Set up the disk configuration.

    ```sh
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./modules/nixosModules/hosts/$HOSTNAME
    ```

4. Install NixOS.

    ```sh
    sudo nixos-install --flake .#$HOSTNAME
    ```

5. Or, as a one-liner.

    ```sh
    sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake .#$HOSTNAME --disk main /dev/nvme0n1
    ```
