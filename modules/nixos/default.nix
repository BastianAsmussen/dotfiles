{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./crypto
    ./desktop
    ./security
    ./virtualization
    ./btrfs.nix
    ./home-manager.nix
    ./keyboard.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
  ];

  btrfs.enable = lib.mkDefault true;

  home-manager.enable = lib.mkDefault true;
  keyboard.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;

  programs.zsh.enable = true;
  users.users.bastian = {
    isNormalUser = true;
    description = "Bastian Asmussen";
    initialPassword = "Password123!";

    extraGroups = ["wheel" "docker" "libvirtd"];
    shell = pkgs.zsh;
  };
}
