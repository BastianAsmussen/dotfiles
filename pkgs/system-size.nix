{pkgs}:
pkgs.writeShellScriptBin "system-size" ''
  nix path-info -Sh /run/current-system | tail -1 | awk '{print $2, $3}'
''
