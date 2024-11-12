{
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    (import ./calculator.nix {inherit pkgs lib;})
  ];
}
