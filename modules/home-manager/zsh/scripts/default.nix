{pkgs, ...}: {
  home.packages = [
    (import ./calculator.nix {inherit pkgs;})
  ];
}
