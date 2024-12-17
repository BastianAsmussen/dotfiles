{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./crypto
    ./desktop
    ./nix
    ./security
    ./virtualisation
    ./bluetooth.nix
    ./bootloader.nix
    ./btrfs.nix
    ./gaming.nix
    ./goxlr.nix
    ./home-manager.nix
    ./keyboard.nix
    ./language.nix
    ./misc.nix
    ./network-manager.nix
    ./nvidia.nix
    ./stylix.nix
    ./user.nix
  ];

  documentation.dev.enable = true;

  btrfs.enable = mkDefault true;
  network-manager.enable = mkDefault true;
  home-manager.enable = mkDefault true;
  keyboard.enable = mkDefault true;

  system.stateVersion = mkDefault "24.05";
}
