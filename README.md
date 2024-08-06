# dotfiles

This is a repository for my NixOS configuration.

## Installation Guide

1. Clone the Git repository.

```sh
nix-shell -p git

git clone https://github.com/BastianAsmussen/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. Set up the disk configuration, e.g. for `limitless`.

```sh
echo "password123" > /tmp/secret.key

sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko ~/dotfiles/hosts/limitless/disko-config.nix
```

3. Install NixOS with the given configuration, e.g. `limitless`.

```sh
sudo nixos-install --flake ~/dotfiles#limitless
```

4. Remember to change the password of the user!

> [!NOTE]
> After installation it may be a requirement to update the [channel](https://nixos.wiki/wiki/Nix_channels) to get `command-not-found` working properly.  
> To do so run `sudo nix-channel --update`.

## Maintenance Guide

1. Update the `flake.lock` file about once per week.

```sh
cd ~/dotfiles

nix flake update
```

2. Make sure it can compile.

```sh
nh os test ~/dotfiles
```

- If it can't build, roll back to a previous version.

```sh
git reset --hard HEAD~1
```

