{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./hardening
    ./vpn
    ./gpg.nix
    ./ssh.nix
    ./yubiKey.nix
  ];

  gpg.enable = mkDefault true;
  tailscale.enable = mkDefault true;
  yubiKey.enable = mkDefault true;
}
