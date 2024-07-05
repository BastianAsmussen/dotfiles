{lib, ...}: {
  imports = [
    ./nvidia.nix
    ./security.nix
    ./stylix.nix
  ];

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;

  stylix.enable = lib.mkDefault true;
}
