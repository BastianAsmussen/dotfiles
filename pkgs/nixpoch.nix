{
  pkgs,
  lib,
}:
pkgs.writeShellScriptBin "nixpoch" ''
  # @describe Show how long ago Nix started being used in your dotfiles repository.
  # @meta version 0.1.0
  # @meta author Bastian Asmussen <bastian@asmussen.tech>
  # @flag -w --watch Continuously update every second
  # @flag -r --raw   Output only raw seconds since first Nix usage
  # @option -b --branch=master Specify branch to search

  function error {
    echo "nixpoch error: $1" >&2
    exit 1
  }

  function uses_nix {
    local hash=$1

    git ls-tree -r --name-only "$hash" | egrep -q 'flake\.nix|shell\.nix|default\.nix|\.nix$'
  }

  function display_pretty {
    now_ts=$(date +%s)
    delta=$((now_ts - first_commit_ts))

    days=$((delta / 86400))
    hours=$(((delta % 86400) / 3600))
    minutes=$(((delta % 3600) / 60))
    seconds=$((delta % 60))

    echo "nixpoch (Nix usage started on '$argc_branch' — $first_commit_date):"
    printf "%dd, %02dh, %02dm and %02ds ago.\n" $days $hours $minutes $seconds
  }

  function main {
    if [ -z "$NH_FLAKE" ]; then
      error "NH_FLAKE is not set, can't find dotfiles!"
    fi

    if [ ! -d "$NH_FLAKE/.git" ]; then
      error "\$NH_FLAKE is not a Git repository: $NH_FLAKE"
    fi

    cd "$NH_FLAKE"
    mapfile -t commits < <(git rev-list --reverse "$argc_branch")

    if [ ''${#commits[@]} -eq 0 ]; then
      error "No commits found on branch '$argc_branch'!"
    fi

    # Binary search for first commit using Nix.
    lo=0
    hi=$((''${#commits[@]} - 1))
    first_nix_commit=""

    while [ $lo -le $hi ]; do
      mid=$(((lo + hi) / 2))
      hash="''${commits[$mid]}"

      if uses_nix "$hash"; then
        first_nix_commit="$hash"
        hi=$((mid - 1))
      else
        lo=$((mid + 1))
      fi
    done

    if [ -z "$first_nix_commit" ]; then
      error "No commit found using Nix on branch '$argc_branch'!"
    fi

    first_commit_ts=$(git show -s --format=%ct "$first_nix_commit")
    first_commit_date=$(date -d "@$first_commit_ts" +"%Y-%m-%d@%H:%M:%S %Z")

    if [ $argc_raw ]; then
      now_ts=$(date +%s)
      echo $((now_ts - first_commit_ts))

      exit 0
    fi

    if [ $argc_watch ]; then
      trap "tput cnorm; exit" INT
      while true; do
        tput civis # Hide cursor.
        tput sc # Save cursor position.
        display_pretty

        tput rc # Restore cursor.
        sleep 1
      done
    else
      display_pretty
    fi
  }

  eval "$(${lib.getExe pkgs.argc} --argc-eval "$0" "$@")"
''
