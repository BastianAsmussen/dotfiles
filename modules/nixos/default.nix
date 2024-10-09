{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./crypto
    ./desktop
    ./nvidia
    ./security
    ./virtualisation
    ./bootloader.nix
    ./btrfs.nix
    ./gaming.nix
    ./goxlr.nix
    ./home-manager.nix
    ./keyboard.nix
    ./language.nix
    ./network-manager.nix
    ./nh.nix
    ./nix.nix
    ./stylix.nix
    ./user.nix
  ];

  btrfs.enable = mkDefault true;
  network-manager.enable = mkDefault true;
  home-manager.enable = mkDefault true;
  keyboard.enable = mkDefault true;

  system.stateVersion = mkDefault "24.05";
}
