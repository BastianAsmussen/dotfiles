# To-Do Tracking

This file tracks things I'm either looking into or haven't gotten around to
yet. Writing them down here helps me fix stuff properly instead of just hacking
around problems.

## Table of Contents

- [Colemak-DH on Delta](#colemak-dh-on-delta)
- [Development Environments](#development-environments)
- [Neovim](#neovim)
- [Impermanence Setup](#impermanence-setup)
- [Linux Hardening](#linux-hardening)
- [SSH](#ssh)

## Colemak-DH on Delta

- [x] Add Colemak-DH with home-row mods for Delta via
  [kanata](./modules/nixosModules/features/kanata.nix). Uses GACS modifier
  order and 200ms tap-hold timing to mirror the Glove80 Glorious Engrammer
  configuration.

### Remaining Work

- Fine-tune kanata config to exactly match further Glove80 customisations.

## Development Environments

I've started using [Nix Flake Templates](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-init.html#description)
to handle development environments and it seems pretty good! Now I'll just have
to implement a template for each language I use, which, as of now consists of:

- [x] Rust
- [x] Go
- [x] C#
- [x] Haskell
- [x] C
- [x] Python

## Neovim

### SSH

- [x] Use the paste buffer of the client when using Neovim on a server via
  native `vim.ui.clipboard.osc52` (Neovim 0.10+), gated behind `$SSH_TTY`.

### Plugin Issues

- [x] [nvim-dap](https://github.com/mfussenegger/nvim-dap) runner selection
  fixed by adding default LLDB configurations for C/C++. Rust is handled by
  rustaceanvim.

## Impermanence Setup

- [x] Option-driven impermanence module following the
  [Goxore/nixconf](https://github.com/Goxore/nixconf) pattern. Three
  persistence paths (`/persist/system`, `/persist/userdata`, `/persist/usercache`)
  with configurable directories/files per category. Uses
  `config.preferences.user.name` for multi-user support and optional btrfs
  root nuking via `persistance.nukeRoot.enable`.
- [x] LUKS/FIDO2 boot fix in a dedicated
  [luks-fido2 module](./modules/nixosModules/features/luks-fido2.nix).

### Remaining Work

- Enable `self.nixosModules.impermanence` in host configurations and populate
  the `persistance.data.*` / `persistance.cache.*` options per host.

## Linux Hardening

- [x] `kptr_restrict`, `dmesg_restrict`, unprivileged userns, ptrace scope.
- [x] Slab and memory hardening boot params.
- [x] Reverse-path drop logging.

### Remaining Work

- Investigate SELinux once NixOS support matures.
- Per-service systemd hardening.

## SSH

- [x] GPG agent forwarding via
  [SSH client module](./modules/homeManagerModules/ssh.nix). Trusted host
  sourced from `nix-secrets`, `StreamLocalBindUnlink` on both sides.
