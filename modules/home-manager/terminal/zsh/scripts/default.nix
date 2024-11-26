{
  pkgs,
  lib,
  ...
}: let
  calculator = import ./calculator.nix {inherit pkgs lib;};
  myip = import ./myip.nix {inherit pkgs lib;};
in {
  home.packages = [
    calculator
    myip
  ];
}
