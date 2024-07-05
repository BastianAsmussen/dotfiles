{lib, ...}: {
  imports = [
    ./home-manager.nix
    ./nvidia.nix
    ./security.nix
    ./stylix.nix
  ];

  home-manager.enable = lib.mkDefault true;

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;

  stylix.enable = lib.mkDefault true;
}
