{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
  ];
  
  home.username = "bastian";
  home.homeDirectory = "/home/bastian";
  
  home.stateVersion = "24.05";
  
  programs.home-manager.enable = true;
}
