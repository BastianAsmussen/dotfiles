{
  pkgs ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
    import nixpkgs {},
}: {
  mit = pkgs.callPackage ./mit {};
  calculator = pkgs.callPackage ./calculator.nix {};
  copy-file = pkgs.callPackage ./copy-file.nix {};
  todo = pkgs.callPackage ./todo.nix {};
}
