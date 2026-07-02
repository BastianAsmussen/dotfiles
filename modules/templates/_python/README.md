# Python Project Template

This project is built using [Nix](https://nixos.org).

## Getting Started

- Enter the development shell with `nix develop`.
- Edit `pyproject.toml` — update `tool.poetry.name` to your project name.

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
nix develop

poetry run python -m src
```
