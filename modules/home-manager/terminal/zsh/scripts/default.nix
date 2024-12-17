{
  pkgs,
  lib,
  ...
}: let
  calculator = import ./calculator.nix {inherit pkgs lib;};
  myip = import ./myip.nix {inherit pkgs lib;};
  system-size = import ./system-size.nix {inherit pkgs lib;};
in {
  home.packages = [
    calculator
    myip
    system-size
  ];
}
