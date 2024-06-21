{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/firefox.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/alacritty.nix
  ];
  
  home.username = "bastian";
  home.homeDirectory = "/home/bastian";
  
  home.stateVersion = "24.05";
  
  environment.pathsToLink = [ "/share/zsh" ];
  
  programs.home-manager.enable = true;
}
