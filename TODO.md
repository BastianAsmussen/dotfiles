# To-Do Tracking

This file tracks things I'm either looking into or haven't gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Development Environments](#development-environments)
- [Neovim](#neovim)
- [Impermanence Setup](#impermanence-setup)
- [AGS Migration](#ags-migration)
- [Linux Hardening](#linux-hardening)
- [File Structure](#file-structure)
- [SSH](#ssh)
- [CI](#ci)
- [Glove80](#glove80)

## Development Environments

I've started using [Nix Flake Templates](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-init.html#description)
to handle development environments and it seems pretty good! Now I'll just have
to implement a template for each language I use, which, as of now consists of:

- [x] Rust
- [ ] Go
- [ ] C#
- [ ] Haskell
- [ ] C
- [ ] Python

## Neovim

### SSH

I want to be able to use the paste buffer of the client when using Neovim on a
server.

### Plugin Issues

- [nvim-dap](https://github.com/mfussenegger/nvim-dap) opens a window to select
  multiple different runners when I press `<F5>`.

## Impermanence Setup

### Current Issues

- **Desyncs**:
  Fresh installs don't always match long-running ones.
  - **Example**: If I change something in my
    [Firefox setup](./modules/home-manager/desktop/firefox), like tweaking
    uBlock Origin settings, those changes don't carry over to new installs
    because they're done imperatively.
- **Installation Problems**:
  When booting a fresh install, LUKS can't find the disk and just hangs.

### Goal

- Get rid of desyncs so fresh installs work the same as a system I've been
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
so I'd like to look into possibly restructuring it in the future.

Some things I'd really like to change would be how I separate modules. The
setup used in [EmergentMind's dotfiles](https://github.com/EmergentMind/nix-config)
looks very promising, and appears to cover all my pain points.

## SSH

When I'm connected to a remote machine I'd like to be able to perform actions
requiring GPG signing, authentication or encryption. Because my GPG keys are
stored on my YubiKey I'll need to find a way to forward that key somehow.
[RemoteForward](https://wiki.gnupg.org/AgentForwarding) looks rather promising
in that regard.

## CI

Look into making `nix flake check` run the entire lint suite, too.

## Glove80

I've added a script to the flake that can flash my [Glove80](https://www.moergo.com/collections/glove80-keyboards/products/glove80-split-ergonomic-keyboard-revision-2)
firmware to the keyboard (`nix run .#glove80`), the end goal is having a
reproducible keyboard layout. I'm thinking this can be achieved using something
like a systemd service.
