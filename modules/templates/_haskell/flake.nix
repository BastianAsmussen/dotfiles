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
          packages.default = pkgs.haskellPackages.developPackage {
            root = ./.;
          };

          devShells.default = pkgs.haskellPackages.developPackage {
            root = ./.;
            returnShellEnv = true;
            modifier =
              drv:
              pkgs.haskell.lib.addBuildTools drv (
                with pkgs.haskellPackages;
                [
                  cabal-install
                  haskell-language-server
                ]
              );
          };
        };
    };
}
