---
name: nixpkgs-stable
description: Use this skill when the user needs a stable fallback for packages that broke on nixos-unstable — reference `pkgs.stable.<name>` to downgrade a specific package without touching the rest of the system. Applies when a package is broken, incompatible, or needs a known-good version.
metadata:
  input_rev: d6df3513510aa548c83868fd22bfddd0a8c0a0d4
  input_hash: sha256-uJZs9Di8I6ciTp6jiojj0HzlNpBkud8ax5aT/O5aJkw=
  when_to_use: nixpkgs stable, nixos-25.11, pkgs.stable, fallback packages
---

## Pin check

`grep -A4 '"nixpkgs-stable"' flake.lock | grep narHash`
Expected: `sha256-uJZs9Di8I6ciTp6jiojj0HzlNpBkud8ax5aT/O5aJkw=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Reference stable packages as `pkgs.stable.<name>` anywhere in a module.
2. The overlay at `modules/overlays.nix:44-50` merges stable into the `stable` namespace.
3. To fall a package back to stable: replace `pkgs.<name>` with `pkgs.stable.<name>`. There is no centralized registry — each override is ad-hoc.

## Gotchas

- nixpkgs-stable is a completely independent nixpkgs instance. Mixing stable and unstable packages can cause ABI mismatches if a library comes from one and its consumer from the other.
- The stable overlay is unconditional — `pkgs.stable` is always available, not just when you declare a fallback. Don't accidentally use it for everything.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#legacyPackages.x86_64-linux.stable.hello.version`
