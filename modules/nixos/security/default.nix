{lib, ...}: {
  imports = [
    ./gpg.nix
    ./ssh.nix
    ./vpn.nix
    ./yubiKey.nix
  ];

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;
}
