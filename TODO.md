# To-Do Tracking

This file tracks things I'm either looking into or haven't gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Developer Environments](#developer-environments)
- [Neovim](#neovim)
- [Impermanence Setup](#impermanence-setup)
- [AGS Migration](#ags-migration)
- [Linux Hardening](#linux-hardening)
- [File Structure](#file-structure)
- [Secrets Management](#secrets-management)
- [SSH](#ssh)

## Developer Environments

I want a proper way to handle ephemeral developer environments. Right now I'm
using [devenv](./modules/home-manager/terminal/direnv.nix), but it feels a bit
like cheating; what I'd really like is to add templates to my flake.

### Inspiration

I've seen a repository called
[nix-templates](https://github.com/MordragT/nix-templates) which might be
pretty useful. Perhaps it could be a flake input?

### Distrobox

I'm also using [Distrobox](https://distrobox.it) for generic Linux environments.
Package installs sometimes don't work as expected due to FHS issues. I'll need
to find a fix for this.

## Neovim

### SSH

I want to be able to use the paste buffer of the client when using Neovim on a
server.

### Plugin Issues

- [otter.nvim](https://github.com/jmbuhr/otter.nvim) sometimes fails to start
  when I enter a file.
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

## Secrets Management

I want to use [sops.nix](https://github.com/Mic92/sops-nix) to manage
repository secrets but my current setup with my GPG keys on my YubiKey doesn't
seem to really work all too well for that.

## SSH

When I'm connected to a remote machine I'd like to be able to perform actions
requiring GPG signing, authentication or encryption. Because my GPG keys are
stored on my YubiKey I'll need to find a way to forward that key somehow.
[RemoteForward](https://wiki.gnupg.org/AgentForwarding) looks rather promising
in that regard.
