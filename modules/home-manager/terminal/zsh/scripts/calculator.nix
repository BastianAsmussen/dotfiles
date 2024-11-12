{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "=" ''
  cat << EOF | ${lib.getExe pkgs.bc}
  scale=64
  $@
  EOF

  exit 0
''
