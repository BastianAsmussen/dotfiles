{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./bottles.nix
    ./docker.nix
    ./kubernetes.nix
    ./qemu.nix
  ];

  bottles.enable = mkDefault true;
  docker.enable = mkDefault true;
  qemu.enable = mkDefault true;
}
