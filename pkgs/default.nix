{pkgs ? import <nixpkgs> {}}: {
  custom-tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer.nix {};
}
