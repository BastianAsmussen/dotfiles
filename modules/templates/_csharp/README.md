# C# Project Template

This project is built using [Nix](https://nixos.org).

## Getting Started

- Enter the development shell with `nix develop`.
- Run the `init.sh` script to rename the project files automatically.

Inside the dev shell, `dotnet build` and `dotnet run` work immediately, and
`csharp-ls` is on the `PATH` for editor integration.

## Usage

### Building

```sh
nix build
```

A hermetic `nix build` needs a NuGet lockfile. The shipped `deps.json` is empty,
which is correct as long as the project pulls no NuGet packages. After adding a
dependency, regenerate it:

```sh
nix build .#default.passthru.fetch-deps
./result deps.json
```

### Running

```sh
nix run
```
