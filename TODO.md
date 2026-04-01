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
  configuration. XKB remains `dk` in niri so Danish keys (æ/ø/å) still work.

### Remaining Work

- Fine-tune kanata config to exactly match any further Glove80 customisations
  (e.g. extra layers, combos) that cannot be inferred from the exported JSON.

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

- [x] Use the paste buffer of the client when using Neovim on a server.
  Configured via Neovim's native `vim.ui.clipboard.osc52` module in
  `extraConfigLuaPost`, activated only when `$SSH_TTY` is set.

### Plugin Issues

- [x] [nvim-dap](https://github.com/mfussenegger/nvim-dap) runner selection
  fixed by adding default LLDB configurations for C/C++. Rust is handled by
  rustaceanvim which registers its own dap configurations.

## Impermanence Setup

### Current Issues

- [x] **Desyncs**: Added an
  [impermanence module](./modules/nixosModules/features/impermanence.nix) with
  both NixOS-level and Home Manager-level persistence. The NixOS module handles
  btrfs root rollback via a blank snapshot and the Home Manager module persists
  user state (Firefox, GPG, password store, etc.).
- [x] **Installation Problems**: Fixed LUKS boot by creating a dedicated
  [luks-fido2 module](./modules/nixosModules/features/luks-fido2.nix) that
  enables systemd initrd (needed for FIDO2 unlocking) and loads `dm-crypt` in
  the initrd — without touching `hardware-configuration.nix`.

### Remaining Work

- Enable `self.nixosModules.impermanence` and the `impermanence` home module
  in host configurations after creating the `/nix/persist` subvolume and the
  `root-blank` btrfs snapshot on existing installs.

## Linux Hardening

- [x] Added kernel pointer restrictions (`kptr_restrict = 2`) — prevents
  leaking KASLR base addresses via `/proc/kallsyms`.
- [x] Added dmesg restrictions (`dmesg_restrict = 1`) — kernel ring buffer
  often leaks driver addresses useful for LPE exploits.
- [x] Disabled unprivileged user namespaces — entry point for many
  container-escape and LPE CVEs (e.g. CVE-2022-0185).
- [x] Restricted ptrace (`yama.ptrace_scope = 1`) — prevents a compromised
  process from attaching to ssh-agent or GPG agent of the same user.
- [x] Added slab and memory hardening boot params — `slab_nomerge` prevents
  cross-cache heap exploits, `init_on_alloc/free` zeroes stale data.
- [x] Enabled reverse-path drop logging in the firewall.

### Remaining Work

- Investigate SELinux once NixOS support matures.
- Consider per-service systemd hardening (`ProtectSystem`, `PrivateTmp`, etc.).

## SSH

- [x] GPG agent forwarding configured via
  [SSH client module](./modules/homeManagerModules/ssh.nix). Only forwards to
  explicitly trusted hosts (not wildcard) to avoid the class of attack
  described in the [Matrix.org incident](https://matrix.org/blog/2019/05/08/post-mortem-and-remediations-for-apr-11-security-incident/#ssh-agent-forwarding-should-be-disabled).
  `StreamLocalBindUnlink` is set on both client and server sides.

### Remaining Work

- Move trusted host addresses into sops-nix secrets instead of hard-coding
  them in the public repository.
