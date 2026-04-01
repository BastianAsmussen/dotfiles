{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: let
        commonArgs = {
          buildInputs = [];
          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ];
        };
      in {
        packages.default = pkgs.stdenv.mkDerivation (commonArgs
          // {
            pname = "sample-project";
            version = "0.1.0";

            src = ./.;

            installPhase = ''
              mkdir -p $out/bin
              cp sample-project $out/bin/
            '';
          });

        devShells.default = pkgs.mkShell (commonArgs
          // {
            buildInputs = with pkgs; [
              gcc
              gnumake
              cmake
              gdb
              valgrind
              clang-tools
            ];
          });
      };
    };
}
