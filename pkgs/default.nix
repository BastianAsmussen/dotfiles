{pkgs ? import <nixpkgs> {}}: {
  tmux-sessionizer = pkgs.callPackage ./tmux-sessionizer.nix {};
}
