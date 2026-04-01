{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: let
        haskellPackages = pkgs.haskellPackages;
      in {
        packages.default = haskellPackages.callCabal2nix "sample-project" ./. {};

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ghc
            cabal-install
            haskell-language-server
            haskellPackages.hoogle
            haskellPackages.hlint
            haskellPackages.ormolu
          ];
        };
      };
    };
}
