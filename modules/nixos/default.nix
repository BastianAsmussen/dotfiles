{lib, ...}: {
  imports = [
    ./home-manager.nix
    ./nix.nix
    ./nvidia.nix
    ./security.nix
    ./stylix.nix
  ];

  nix.enable = lib.mkDefault true;

  home-manager.enable = lib.mkDefault true;

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;

  stylix.enable = lib.mkDefault true;
}
