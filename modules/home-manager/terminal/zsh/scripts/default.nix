{
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    (import ./calculator.nix {inherit lib pkgs;})
  ];
}
