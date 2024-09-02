{lib, ...}: {
  imports = [
    ./crypto
    ./desktop
    ./security
    ./virtualisation
    ./bootloader.nix
    ./btrfs.nix
    ./fonts.nix
    ./goxlr.nix
    ./home-manager.nix
    ./keyboard.nix
    ./language.nix
    ./network-manager.nix
    ./nh.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
    ./user.nix
  ];

  btrfs.enable = lib.mkDefault true;
  network-manager.enable = lib.mkDefault true;
  home-manager.enable = lib.mkDefault true;
  keyboard.enable = lib.mkDefault true;
}
