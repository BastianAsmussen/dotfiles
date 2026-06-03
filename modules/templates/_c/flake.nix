{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        { pkgs, ... }:
        {
          packages.default = pkgs.stdenv.mkDerivation {
            pname = "sample-project";
            version = "0.1.0";
            src = ./.;

            makeFlags = [ "PREFIX=$(out)" ];

            meta.mainProgram = "sample-project";
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              clang
              clang-tools
              gnumake
              gdb
            ];
          };
        };
    };
}
