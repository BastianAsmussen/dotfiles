# To-Do Tracking

This file tracks things I'm either looking into or haven't gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Noctalia Idle](#noctalia-idle)
- [Neovim Undotree](#neovim-undotree)
- [Development Environments](#development-environments)

## Noctalia Idle

Add a toggle for enabling idle. Right now on `epsilon`, it will turn off the
monitors, but them back on will make Noctalia bug out.

## Neovim Undotree

Undotree only works on a per-session basis, new sessions don't keep old edits.
Figure out how to save the files correctly to disk.

## Development Environments

I've started using [Nix Flake Templates](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-init.html#description)
to handle development environments and it seems pretty good! Now I'll just have
to implement a template for each language I use, which, as of now consists of:

- [x] Rust
- [x] Go
- [ ] C#
- [x] Haskell
- [x] C
- [x] Python
