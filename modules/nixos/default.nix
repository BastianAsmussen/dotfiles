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
    ./home-manager.nix
    ./keyboard.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
  ];

  environment.systemPackages = with pkgs; [
    ripgrep
    gitui
    bitwarden
    qbittorrent
    discord
    spotify
    mpv
    wget
    go
    manix
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
