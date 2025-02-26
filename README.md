# dotfiles

This is a repository for my NixOS configuration.

## Table of Contents

- [Installation Guide](#installation-guide)
- [Maintenance Guide](#maintenance-guide)
- [To-Do Tracking](#to-do-tracking)
- [Development Templates](#development-templates)

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

   2. Set manually, e.g. `lambda`.

      ```sh
      HOSTNAME=lambda
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

## Maintenance Guide

1. I recommend updating the [flake.lock](./flake.lock) file about once per week.

   ```sh
   nh os switch --update
   ```

> [!NOTE]
> If it can't build, roll back the [flake.lock](./flake.lock) file to a
> previous version.  
> Running `git restore flake.lock` should be sufficient.

### Rename Host

1. Move the host directory, e.g. `lambda` -> `epsilon`.

   ```sh
   mv hosts/lambda hosts/epsilon
   ```

2. Switch to new configuration.

   ```sh
   nh os switch -H epsilon
   ```

> [!WARNING]
> The hostname won't update automatically!  
> To update the hostname, either reboot the computer, or restart the current session.

## To-Do Tracking

I track stuff I need to get done and stuff that annoys me about my current
setup in a file called [TODO.md](./TODO.md).  
If you have suggestions or notice something that could be improved, feel free
to open a pull request. I'll review and consider integrating your
contributions.

## Development Templates

You can use this flake for development environment templates.

### List Templates

```sh
nix-shell -p jq --run "nix flake show self --all-systems --json | jq .templates"
```

### Use Template

> [!NOTE]
> Because we override the [Nix registry](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-registry#description) > [here](./modules/nixos/nix/default.nix), we can simply use the `self` registry
> entry which references this flake.

### Rust Example

```sh
mkdir ~/Projects/example
cd ~/Projects/example

nix flake init -t self#rust
```
