{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "system-size" ''
  ${lib.getExe pkgs.nix} path-info -Sh /run/current-system | tail -1 | awk '{print $2, $3}'
''
