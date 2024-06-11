{
  imports = [
    ./home-manager.nix
    ./nixos.nix
  ];

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
