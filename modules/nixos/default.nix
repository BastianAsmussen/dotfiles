{lib, ...}: {
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

  btrfs.enable = lib.mkDefault true;
  network-manager.enable = lib.mkDefault true;
  home-manager.enable = lib.mkDefault true;
  keyboard.enable = lib.mkDefault true;
}
