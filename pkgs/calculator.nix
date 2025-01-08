{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "=" ''
  cat << EOF | ${lib.getExe pkgs.bc}
  scale=2
  $@
  EOF

  exit 0
''
