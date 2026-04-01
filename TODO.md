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

- [x] Add Colemak-DH with home-row mod support for Delta via
  [kanata](./modules/nixosModules/features/kanata.nix).

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
  OSC 52 clipboard support.

### Plugin Issues

- [x] [nvim-dap](https://github.com/mfussenegger/nvim-dap) runner selection
  fixed by adding default LLDB configurations for C/C++.

## Impermanence Setup

### Current Issues

- [x] **Desyncs**: Added an
  [impermanence module](./modules/nixosModules/features/impermanence.nix) that
  explicitly persists needed user and system state directories (Firefox
  profile, GPG, password store, etc.).
- [x] **Installation Problems**: Fixed LUKS boot issues by enabling the
  systemd-based initrd (required for FIDO2 unlocking), adding `dm-crypt` to
  initrd kernel modules, and including additional USB storage drivers.

### Goal

- [x] Get rid of desyncs so fresh installs work the same as a system I've
  been using for a long time.

### Remaining Work

- Enable `self.nixosModules.impermanence` in host configurations once the
  `/nix/persist` subvolume is created on existing installs.

## Linux Hardening

- [x] Added kernel pointer and dmesg restrictions (`kptr_restrict`,
  `dmesg_restrict`).
- [x] Added ptrace restrictions (`yama.ptrace_scope`).
- [x] Disabled core dumps (`fs.suid_dumpable`, `systemd.coredump`).
- [x] Added kernel boot parameters for slab hardening and memory
  initialization.
- [x] Enabled firewall with deny-all-inbound default.

### Remaining Work

- Investigate SELinux once NixOS support matures.
- Consider per-service systemd hardening (`ProtectSystem`, `PrivateTmp`, etc.).

## SSH

- [x] GPG agent forwarding configured via
  [SSH client module](./modules/homeManagerModules/ssh.nix) and
  `enableExtraSocket` in
  [GPG module](./modules/nixosModules/features/gpg.nix). Remote machines can
  now use the local YubiKey for GPG operations over SSH.
