{
  description = "Haskell development environment.";

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
        let
          hp = pkgs.haskellPackages;
          pkg = hp.callCabal2nix "sample-project" ./. { };
        in
        {
          packages.default = pkg;

          devShells.default = hp.shellFor {
            packages = _: [ pkg ];
            nativeBuildInputs = with hp; [
              cabal-install
              haskell-language-server
              ghcid
            ];
          };
        };
    };
}
