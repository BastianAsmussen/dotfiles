{
  description = "C development environment.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        { pkgs, ... }:
        {
          packages.default = pkgs.stdenv.mkDerivation {
            pname = "sample-project";
            version = "0.1.0";
            src = ./.;

            installPhase = ''
              install -Dm755 sample-project $out/bin/sample-project
            '';
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              gcc
              gnumake
              gdb
              clang-tools
              valgrind
            ];
          };
        };
    };
}
