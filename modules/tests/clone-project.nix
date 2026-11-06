{
  perSystem =
    { lib, pkgs, ... }:
    let
      cloneProject = pkgs.writeTextFile {
        name = "clone-project-test";
        executable = true;
        destination = "/bin/clone-project";
        text = ''
          #!${pkgs.bashInteractive}/bin/bash
          ${builtins.readFile ../packages/clone-project/clone-project.sh}
        '';
      };

      mockFzf = pkgs.writeShellScriptBin "fzf" ''
        cat >/dev/null
        printf 'Personal\n'
      '';

      mockGit = pkgs.writeShellScriptBin "git" ''
        {
          printf 'git'
          printf ' %s' "$@"
          printf '\n'
        } >> "$TEST_LOG"

        for arg; do
          target=$arg
        done

        if [ "''${MOCK_GIT_FAIL:-0}" = 1 ]; then
          mkdir -p "$target"
          printf 'fatal: original clone failure\n' >&2
          exit 1
        fi

        mkdir -p "$target/.git"
      '';

      mockTmux = pkgs.writeShellScriptBin "tmux" ''
        {
          printf 'tmux'
          printf ' %s' "$@"
          printf '\n'
        } >> "$TEST_LOG"

        if [ "$1" = has-session ]; then
          exit 1
        fi
      '';

      mockPath = lib.concatStringsSep ":" [
        "${mockFzf}/bin"
        "${mockGit}/bin"
        "${mockTmux}/bin"
        "${pkgs.coreutils}/bin"
        "${pkgs.gnugrep}/bin"
      ];

      editingTest = pkgs.writeText "clone-project-editing.exp" ''
        set timeout 10
        spawn {*}$argv

        expect {
          "Repo" {}
          timeout { exit 1 }
          eof { exit 1 }
        }

        # Left and Delete should remove the final X without adding escape bytes.
        send -- "owner/repoX"
        send -- "\033OD"
        send -- "\033\[3~"
        send -- "\r"

        expect {
          eof {}
          timeout { exit 1 }
        }

        set result [wait]
        exit [lindex $result 3]
      '';
    in
    {
      checks.tests-clone-project =
        pkgs.runCommandLocal "tests-clone-project"
          {
            nativeBuildInputs = with pkgs; [
              expect
              gnugrep
            ];
          }
          ''
            export HOME="$PWD/home"
            export TMPDIR="$PWD/tmp"
            export TEST_LOG="$PWD/commands.log"
            export PATH="${mockPath}"
            export TERM=xterm
            export TERMINFO="${pkgs.ncurses}/share/terminfo"

            mkdir -p "$HOME" "$TMPDIR"
            : > "$TEST_LOG"

            ${lib.getExe pkgs.expect} ${editingTest} ${lib.getExe cloneProject}

            grep -F 'git clone --progress -- git@github.com:owner/repo.git ' "$TEST_LOG"
            grep -F 'tmux new-session -d -s repo -c ' "$TEST_LOG"
            grep -Fx 'tmux switch-client -t =repo' "$TEST_LOG"
            test -d "$HOME/Projects/Personal/repo/.git"

            # A failed clone must retain its original error and clean up its partial directory.
            : > "$TEST_LOG"
            set +e
            output=$(printf 'owner/failure\n' | MOCK_GIT_FAIL=1 ${lib.getExe cloneProject} 2>&1)
            status=$?
            set -e

            printf '%s\n' "$output"
            test "$status" -ne 0
            test "$(grep -c '^git clone' "$TEST_LOG")" -eq 1
            grep -F 'original clone failure' "$TMPDIR"/clone-project.*
            test ! -e "$HOME/Projects/Personal/failure"
            shopt -s nullglob
            partial_clones=("$HOME/Projects/Personal/failure.tmp."*)
            test "''${#partial_clones[@]}" -eq 0

            touch "$out"
          '';
    };
}
