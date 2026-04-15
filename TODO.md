# To-Do Tracking

This file tracks things I'm either looking into or haven't gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Neovim Plugins](#neovim-plugins)
- [Development Environments](#development-environments)
- [Impermanence Setup](#impermanence-setup)

## Neovim Plugins

- [x] Resolved `harpoon` / `tmux-navigator` keybind overlap (`<C-j>`, `<C-k>`,
  `<C-l>`). Harpoon slots moved to `<leader>1-4`.

## Development Environments

I've started using [Nix Flake Templates](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-init.html#description)
to handle development environments and it seems pretty good! Now I'll just have
to implement a template for each language I use, which, as of now consists of:

- [x] Rust
- [x] Go
- [ ] C#
- [ ] Haskell
- [ ] C
- [x] Python

## Impermanence Setup

### Current Issues

- **Desyncs**:
  Fresh installs don't always match long-running ones.
  - **Example**: If I change something in my
    [Firefox setup](./modules/homeManagerModules/firefox.nix), like tweaking
    uBlock Origin settings, those changes don't carry over to new installs
    because they're done imperatively.
- **Installation Problems**:
  When booting a fresh install, LUKS can't find the disk and just hangs.

### Goal

- Get rid of desyncs so fresh installs work the same as a system I've been
  using for a long time.
