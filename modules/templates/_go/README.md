# Go Project Template

This project is built using [Nix](https://nixos.org).

## Getting Started

- Enter the development shell with `nix develop`.
- Update the module path in `go.mod` to match your project name.

## Usage

### Building

```sh
nix build
```

### Testing

```sh
nix flake check --all-systems
```

### Running

```sh
nix run
```

## Development Tools

This project uses [gomod2nix](https://github.com/nix-community/gomod2nix) to
help with managing Go module dependencies. To avoid having to download
dependencies multiple times in the Nix store, you can import them directly from
the Go cache.

```sh
gomod2nix import
```
