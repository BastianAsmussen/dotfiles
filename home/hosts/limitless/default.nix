{
  pkgs,
  lib,
  ...
}: let
  homeDirectory = "/home/bastian";
in {
  imports = [
    ../../modules
  ];

  home = {
    username = "bastian";
    inherit homeDirectory;
  };
}
