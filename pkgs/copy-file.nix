{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "cf" ''
  # @describe Copy a file to the system clipboard.
  #
  # @meta version 0.1.0
  # @meta author Bastian Asmussen <bastian@asmussen.tech>
  # @arg file! The file to read

  function get_clipboard {
      case "$XDG_SESSION_TYPE" in
          wayland) echo ${pkgs.wl-clipboard}/bin/wl-copy ;;
          *) echo ${lib.getExe pkgs.xclip} ;;
      esac
  }

  function main {
      set -o pipefail

      cat $argc_file | $(get_clipboard)
  }

  eval "$(${lib.getExe pkgs.argc} --argc-eval "$0" "$@")"
''
