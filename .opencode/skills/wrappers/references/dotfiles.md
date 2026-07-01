# wrappers — Reference

## What it is

`wrappers` (`github:Lassulus/wrappers`) is a low-level Nix package wrapping library providing `wrapModule` — a function that defines a self-contained module for wrapping a Nix package with configuration.

## Why it's in the dotfiles

Used only for `wlr-which-key`, which needs its YAML config passed as a CLI argument to the wrapped binary.

## How it's wired

- **Input declaration:** `flake.nix:84-87`
- **Usage:** `modules/wrappedPrograms/wlr-which-key.nix:37` — `inputs.wrappers.lib.wrapModule` defines `self.wrapperModules.which-key`
- **Architecture:** `wrapModule` creates module with `options` (YAML-formatted config → CLI argument) and `config.package` (derivation to wrap)
- **Relationship:** `wrappers` provides the low-level primitive; `wrapper-modules` uses it internally for the `.wrap` method

## Hosts using it

| Host | How |
|------|-----|
| ε | Via niri feature → wlr-which-key wrapper |
| δ | Via niri feature → wlr-which-key wrapper |
