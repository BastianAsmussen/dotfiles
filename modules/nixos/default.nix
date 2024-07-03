{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nvidia.nix
    ./security.nix
  ];

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
}
