{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    naersk.url = "github:nix-community/naersk";
  };

  outputs = inputs @ {
    flake-parts,
    naersk,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: let
        commonArgs = {
          buildInputs = [];
          nativeBuildInputs = [];
        };

        naerskLib = pkgs.callPackage naersk {};
      in {
        packages.default = naerskLib.buildPackage (commonArgs
          // {
            src = ./.;
          });

        devShells.default = pkgs.mkShell (commonArgs
          // {
            buildInputs = with pkgs; [
              cargo
              rustc
              rustfmt
              clippy
              rust-analyzer
            ];

            env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          });
      };
    };
}
