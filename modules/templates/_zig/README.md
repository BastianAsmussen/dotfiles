# Zig Project Template

This project is built using [Nix](https://nixos.org) and
[zig2nix](https://github.com/Cloudef/zig2nix).

## Getting Started

- Enter the development shell with `nix develop`.
- Run the `init.sh` script to rename the project files automatically.

## Usage

### Building

```sh
nix build
```

### Running

```sh
nix run
```

## Notes

The `zig` and `zls` provided by the dev shell are pinned by `zig2nix` to match
each other. To add dependencies, edit `build.zig.zon`; `zig2nix` derives the
Nix lock from it automatically on the next build.
