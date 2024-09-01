{pkgs}:
pkgs.writeShellScriptBin "=" ''
  cat << EOF | ${pkgs.bc}/bin/bc
  scale=64
  $@
  EOF

  exit 0
''
