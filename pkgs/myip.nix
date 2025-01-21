{pkgs}:
pkgs.writeShellScriptBin "myip" ''
  curl -s ifconfig.me \
    && echo ""
''
