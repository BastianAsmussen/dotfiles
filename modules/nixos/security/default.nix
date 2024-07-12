{lib, ...}: {
  imports = [
    ./gpg.nix
    ./sshServer.nix
    ./vpn.nix
    ./yubiKey.nix
  ];

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;
}
