{lib, ...}: {
  imports = [
    ./crypto
    ./desktop
    ./security
    ./virtualization
    ./bootloader.nix
    ./btrfs.nix
    ./goxlr.nix
    ./home-manager.nix
    ./keyboard.nix
    ./language.nix
    ./nh.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
    ./user.nix
  ];

  btrfs.enable = lib.mkDefault true;

  home-manager.enable = lib.mkDefault true;
  keyboard.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;
}
