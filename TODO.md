# To-Do Tracking

This file tracks things I’m either looking into or haven’t gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Developer Environments](#developer-environments)
- [Neovim](#neovim)
- [Firefox](#firefox)
- [Disko Command](#disko-command)
- [Impermanence Setup](#impermanence-setup)
- [AGS Migration](#ags-migration)
- [Linux Hardening](#linux-hardening)
- [File Structure](#file-structure)
- [Secrets Management](#secrets-management)

## Developer Environments

I want a proper way to handle ephemeral developer environments. Right now I'm
using [devenv](./modules/home-manager/terminal/devenv.nix), but it feels a bit
like cheating; what I'd really like is to add templates to my flake.

### Inspiration

I've seen a repository called
[nix-templates](https://github.com/MordragT/nix-templates) which might be
pretty useful. Perhaps it could be a flake input?

## Neovim

### Plugins

Here's a list of Neovim plugins I'd like to take a look at integrating in the
future:

- [undotree](https://github.com/mbbill/undotree)

### Issues

- [otter.nvim](https://github.com/jmbuhr/otter.nvim) seems to fail to start
  when I enter a Nix file.

## Firefox

### Broken Features

- DRM: Currently, DRM simply refuses to install.
- Image Rendering: Some images appear to render totally glitched.

### Extensions

- uBlock Origin: I'd like to be able to customize the extension through Nix.

## Disko Command

The command I use for setting up my disk layout seems to be deprecated. I need
to figure out a new way to handle it soon.

## Impermanence Setup

### Current Issues

- **Desyncs**:
  Fresh installs don’t always match long-running ones.
  - **Example**: If I change something in my
    [Firefox setup](./modules/home-manager/desktop/firefox), like tweaking
    uBlock Origin settings, those changes don’t carry over to new installs
    because they’re done imperatively.
- **Installation Problems**:
  When booting a fresh install, LUKS can’t find the disk and just hangs.

### Goal

- Get rid of desyncs so fresh installs work the same as a system I’ve been
  using for a long time.

## AGS Migration

I'm considering [migrating AGS](https://aylur.github.io/ags/guide/migrate.html)
to [Astal](https://aylur.github.io/astal).

### Status

- Currently, I'm pinning the flake input to
  [v1](https://github.com/Aylur/ags/tree/v1).
- Astal introduced quite a bit of breaking changes, so it'll probably take me a
  while to migrate.

## Linux Hardening

I'm currently working on [hardening](./modules/nixos/security/hardening.nix) my
systems. I'd like to look into SELinux some more for that reason and see what
other people do to harden their systems.

## File Structure

I'm not exactly super thrilled about how my dotfiles structure is at the moment,
so I’d like to look into possibly restructuring it in the future. Some things
I'd really like to change would be how I separate modules.

For something like my [NixVim](https://github.com/nix-community/nixvim) module:

```
modules/home-manager/terminal/nixvim/
├── plugins/
│   ├── lualine.nix
│   └── default.nix
└── default.nix
```

In `plugins/`, I enable all one-liners in `default.nix` and put the rest of the
plugins in separate files, like this:

```nix
{
  imports = [
    ./lualine.nix
    # ...
  ];

  programs.nixvim.plugins = {
    bufferline.enable = true;
    # ...
  };
}
```

I’m gradually moving away from this setup, but it’s still not enough. I’m
considering a full re-ordering of my structure since I haven’t really found a
good strategy for it yet. Another thing I want to explore is "custom libs," so
I don’t have to import an entire file just to access a single function I defined.

## Secrets Management

I want to use [sops.nix](https://github.com/Mic92/sops-nix) to manage
repository secrets but my current setup with my GPG keys on my YubiKey doesn't
seem to really work all too well for that.
