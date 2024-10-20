{
  lib,
  pkgs,
  ...
}: {
  home.shellAliases.cat = "${lib.getExe pkgs.bat} --plain";

  programs.bat.enable = true;
}
