{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./android.nix
    ./bottles.nix
    ./docker.nix
    ./kubernetes.nix
    ./qemu.nix
  ];

  android.enable = mkDefault true;
  bottles.enable = mkDefault true;
  docker.enable = mkDefault true;
  qemu.enable = mkDefault true;
}
