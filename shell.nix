{
  pkgs ?
  # If 'pkgs' isn't defined, instantiate 'nixpkgs' from locked commit.
  let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
    import nixpkgs {},
}:
pkgs.mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";

  packages = with pkgs; [
    nix
    git
    neovim
    fzf

    # Code Linting.
    statix
    deadnix
    alejandra
    flake-checker
  ];
}