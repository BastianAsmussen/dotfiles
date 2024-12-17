{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./hardening
    ./gpg.nix
    ./ssh.nix
    ./vpn.nix
    ./yubiKey.nix
  ];

  gpg.enable = mkDefault true;
  vpn.enable = mkDefault true;
  yubiKey.enable = mkDefault true;
}
