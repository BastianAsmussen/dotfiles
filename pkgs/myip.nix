{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "myip" ''
  ${lib.getExe pkgs.curl} -s ifconfig.me \
    && echo ""
''
