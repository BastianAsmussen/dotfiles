{lib, ...}: {
  imports = [
    ./docker.nix
    ./kubernetes.nix
    ./qemu.nix
  ];

  docker.enable = lib.mkDefault true;
  qemu.enable = lib.mkDefault true;
}
