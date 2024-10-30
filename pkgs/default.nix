{pkgs ? import <nixpkgs> {}}: {
  docker-desktop = pkgs.callPackage ./docker-desktop.nix {};
}
