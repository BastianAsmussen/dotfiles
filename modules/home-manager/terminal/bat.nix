{
  lib,
  pkgs,
  ...
}: {
  home.shellAliases.cat = "${lib.getExe pkgs.bat} --plain --no-paging";

  programs.bat.enable = true;
}
