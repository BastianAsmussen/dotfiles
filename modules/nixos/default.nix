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
    ./bootloader.nix
    ./btrfs.nix
    ./goxlr.nix
    ./home-manager.nix
    ./keyboard.nix
    ./language.nix
    ./nh.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
  ];

  btrfs.enable = lib.mkDefault true;

  home-manager.enable = lib.mkDefault true;
  keyboard.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    bitwarden
    qbittorrent
    spotify
  ];

  programs.zsh.enable = true;

  users.users.bastian = {
    isNormalUser = true;
    description = "Bastian Asmussen";
    initialPassword = "Password123!";

    extraGroups = ["wheel" "docker" "libvirtd" "networkmanager"];
    shell = pkgs.zsh;
  };
}
