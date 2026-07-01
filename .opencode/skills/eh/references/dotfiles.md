# eh — Reference

## What it is

`eh` (`github:NotAShelf/eh`) is a multicall Rust binary providing ergonomic Nix CLI shortcuts with auto-retry when commands fail due to `--impure`, `--allow-unfree`, or broken/insecure flags.

## Why it's in the dotfiles

Epsilon and delta need interactive Nix CLI usage. `ns`/`nb`/`nr`/`nd` are shorter and smarter than raw `nix` subcommands.

## How it's wired

- **Input declaration:** `flake.nix:76`
- **Feature module:** `modules/nixosModules/features/eh.nix` (8 lines, simple enable)
- **Host imports:** epsilon's and delta's `configuration.nix` via `self.nixosModules.eh`

## Hosts using it

| Host | How |
|------|-----|
| ε | Imported via feature module |
| δ | Imported via feature module |
