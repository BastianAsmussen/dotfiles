# dotfiles

This is a repository for my NixOS configuration.

## Table of Contents

- [Installation Guide](#installation-guide)
- [Maintenance Guide](#maintenance-guide)
- [To-Do Tracking](#to-do-tracking)

## Installation Guide

1. Get the source code.

   1. Enter a Nix shell with Git.

      ```sh
      nix-shell -p git
      ```

   2. Clone the Git repository.

      ```sh
      git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles
      cd ~/dotfiles
      ```

   3. Enter the provided Nix development shell.
      
      ```sh
      nix-shell
      ```

   4. Or, as a one-liner.
      
      ```sh
      nix-shell -p git --run "git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles && cd ~/dotfiles && nix-shell"
      ```

2. Choose a host.

   1. View available host options.

      ```sh
      HOSTNAME=$(ls ~/dotfiles/hosts | fzf)
      ```

   2. Set manually, e.g. `limitless`.

      ```sh
      HOSTNAME=limitless
      ```

3. Set up the disk configuration.

   ```sh
   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
       --write-efi-boot-entries \
       --mode disko ~/dotfiles/hosts/$HOSTNAME/disko-config.nix
   ```

4. Install NixOS with the given configuration.

   ```sh
   sudo nixos-install --flake ~/dotfiles#$HOSTNAME
   ```

> [!IMPORTANT]
> Remember to change the password of the user!

---

> [!TIP]
> After installation it may be a requirement to update the [channel](https://nixos.wiki/wiki/Nix_channels)
> to get `command-not-found` working properly.  
> To do so, run `sudo nix-channel --update`.

## Maintenance Guide

1. I recommend updating the [flake.lock](./flake.lock) file about once per week.

   ```sh
   nh os switch --update
   ```

> [!NOTE]
> If it can't build, roll back the [flake.lock](./flake.lock) file to a
> previous version.  
> Running `git restore flake.lock` should be sufficient.

## To-Do Tracking

I track stuff I need to get done and stuff that annoys me about my current
setup in a file called [TODO.md](./TODO.md).  
If you have suggestions or notice something that could be improved, feel free
to open a pull request. I'll review and consider integrating your
contributions.
