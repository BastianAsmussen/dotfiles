{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nvidia.nix
  ];

  nvidia.enable = lib.mkDefault false;
}
