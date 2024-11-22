# dotfiles

This is a repository for my NixOS configuration.

## Table of Contents

- [Installation Guide](#installation-guide)
- [Maintenance Guide](#maintenance-guide)
- [To-Do Tracking](#to-do-tracking)

## Installation Guide

1. Clone the Git repository.

```sh
nix-shell -p git

git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. Set up the disk configuration, e.g. for `limitless`.

```sh
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko ~/dotfiles/hosts/limitless/disko-config.nix
```

3. Install NixOS with the given configuration, e.g. `limitless`.

```sh
sudo nixos-install --flake ~/dotfiles#limitless
```

4. Remember to change the password of the user!

> [!NOTE]
> After installation it may be a requirement to update the [channel](https://nixos.wiki/wiki/Nix_channels)
> to get `command-not-found` working properly.  
> To do so, run `sudo nix-channel --update`.

## Maintenance Guide

1. Update the `flake.lock` file about once per week.

```sh
nh os switch --update
```

- If it can't build, roll back to a previous version.

```sh
git reset --hard HEAD
```

## To-Do Tracking

I track stuff I need to get done and stuff that annoys me about my current
setup in a file called [TODO.md](./TODO.md).  
If you have suggestions or notice something that could be improved, feel free
to open a pull request. I'll review and consider integrating your
contributions.
