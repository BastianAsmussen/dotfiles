{
  pkgs ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
    import nixpkgs {},
  nixvim ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixvim.locked;
  in
    builtins.getFlake "github:${lock.owner}/${lock.repo}/${lock.rev}",
}: let
  neovim = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    module = import ./modules/homeManagerModules/_nixvim-config.nix;
  };
in
  pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";

    packages = [
      pkgs.git
      pkgs.fzf
      pkgs.just

      neovim
    ];
  }
