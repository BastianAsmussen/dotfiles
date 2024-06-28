{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/firefox.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/zsh.nix
  ];

  home.username = "bastian";
  home.homeDirectory = "/home/bastian";

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
