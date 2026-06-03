{
  description = "Zig development environment.";

  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs =
    { zig2nix, ... }:
    let
      flake-utils = zig2nix.inputs.flake-utils;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        env = zig2nix.outputs.zig-env.${system} { };
      in
      {
        packages.default = env.package {
          src = env.pkgs.lib.cleanSource ./.;

          nativeBuildInputs = [ ];
          buildInputs = [ ];
        };

        apps.default = env.app [ ] ''zig build run -- "$@"'';

        # `env.mkShell` already provides a matching `zig` and `zls`.
        devShells.default = env.mkShell { };
      }
    );
}
