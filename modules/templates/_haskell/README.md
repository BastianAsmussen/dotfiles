# Haskell Project Template

This project is built using [Nix](https://nixos.org).

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

Inside the dev shell, `cabal build` and `cabal run` work as usual, and
`haskell-language-server` is on the `PATH` for editor integration.
