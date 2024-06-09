{ config, pkgs, ... }:
{
  enable = true;
  lfs.enable = true;
  
  userName = "Bastian Asmussen";
  userEmail = "bastian@asmussen.tech";
  
  signing.key = null;
  signing.signByDefault = true;

  extraConfig = {
    pull.rebase = true;
    init.defaultBranch = "master";
  };
}

