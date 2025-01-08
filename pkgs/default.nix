{pkgs ? import <nixpkgs> {}}: {
  mit = pkgs.callPackage ./mit {};
  calculator = pkgs.callPackage ./calculator.nix {};
  myip = pkgs.callPackage ./myip.nix {};
  system-size = pkgs.callPackage ./system-size.nix {};
  todo = pkgs.callPackage ./todo.nix {};
}
