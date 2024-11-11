{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./gpg.nix
    ./hardening.nix
    ./ssh.nix
    ./vpn.nix
    ./yubiKey.nix
  ];

  gpg.enable = mkDefault true;
  vpn.enable = mkDefault true;
  yubiKey.enable = mkDefault true;
}
