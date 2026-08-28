{
  flake.homeModules.fish =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Home Manager's plugin loader looks for functions/, conf.d/ and
      # completions/ at the root of `src`. The built derivations install to
      # share/fish/vendor_*.d instead, so pass the upstream tree.
      plugin = name: {
        inherit name;
        src = pkgs.fishPlugins.${name}.src;
      };

      # Directory shorthands, expanded anywhere on the line: `mv ~dl/foo .`.
      namedDirs = {
        cfg = "~/dotfiles";
        sec = "~/nix-secrets";
        dl = "~/Downloads";
        personal = "~/Projects/Personal";
        work = "~/Projects/Work";
        school = "~/Projects/School";
      };

      # Only reachable inside the distrobox container, which shares $HOME and
      # so reads this config.
      pacmanAbbrs = {
        pacupg = "sudo pacman -Syu";
        pacin = "sudo pacman -S";
        pacins = "sudo pacman -U";
        pacinsd = "sudo pacman -S --asdeps";
        pacre = "sudo pacman -R";
        pacrem = "sudo pacman -Rns";
        pacrep = "pacman -Si";
        pacreps = "pacman -Ss";
        pacloc = "pacman -Qi";
        paclocs = "pacman -Qs";
        pacls = "pacman -Ql";
        pacown = "pacman -Qo";
        pacupd = "sudo pacman -Sy";
        pacmir = "sudo pacman -Syy";
        paclean = "sudo pacman -Sc";
        paclr = "sudo pacman -Scc";
        pacfileupg = "sudo pacman -Fy";
        pacfiles = "pacman -F";
        paclsorphans = "pacman -Qdt";
        pacrmorphans = "sudo pacman -Rs (pacman -Qtdq)";
        pacmanallkeys = "sudo pacman-key --refresh-keys";
      };
    in
    {
      programs = {
        nix-your-shell = {
          enable = true;
          enableFishIntegration = true;
        };

        fish = {
          enable = true;

          plugins = map plugin [
            "fzf-fish" # Ctrl-T files, Ctrl-R history, Ctrl-Alt-F git status.
            "plugin-git"
            "plugin-sudope" # Esc Esc to prefix sudo.
            "autopair"
            "colored-man-pages"
          ];

          shellAliases = {
            c = "clear";
            cp = "cp --recursive";
            rm = "rm --recursive";
            mkdir = "mkdir --parents";
            run-help = "man";
            grep = "grep --color=auto";

            # The eza integration provides ls/ll/la/lt/lla but not this one.
            l = "eza -lah";

            myip = "curl --silent --write-out '\n' https://ifconfig.me/";
            system-size = "nix path-info -Sh /run/current-system | awk '{ print $2, $3 }'";
          };

          shellAbbrs = {
            g = "git";
            gcmsg = "git commit --message";
            grs = "git restore";
            md = "mkdir --parents";
            "-" = "cd -";

            # plugin-git leaves these undefined.
            gpr = "git pull --rebase";
            grhs = "git reset --soft";
            gstaa = "git stash apply";
            gbm = "git branch --move";
            gpf = "git push --force-with-lease --force-if-includes";
            "gpf!" = "git push --force";
            glgp = "git log --stat --patch";
            glgm = "git log --graph --max-count=10";

            # plugin-git defines these, but not equivalently.
            gcl = "git clone --recurse-submodules";
            gtv = "git tag | sort -V";

            named_dirs = {
              position = "anywhere";
              regex = "~(${lib.concatStringsSep "|" (lib.attrNames namedDirs)})(/.*)?";
              function = "expand_named_dir";
            };

            # Pipes and redirections, expanded mid-line.
            G = {
              position = "anywhere";
              expansion = "| grep";
            };

            RG = {
              position = "anywhere";
              expansion = "| rg";
            };

            J = {
              position = "anywhere";
              expansion = "| jq";
            };

            NO = {
              position = "anywhere";
              expansion = ">/dev/null";
            };

            NE = {
              position = "anywhere";
              expansion = "2>/dev/null";
            };

            NUL = {
              position = "anywhere";
              expansion = ">/dev/null 2>&1";
            };

            C = {
              position = "anywhere";
              expansion = "| wl-copy";
            };
          };

          binds = {
            "ctrl-p".command = "history-prefix-search-backward";
            "ctrl-n".command = "history-prefix-search-forward";
            "ctrl-x,ctrl-e".command = "edit_command_buffer";
            "ctrl-x,l".command = "clear-screen-and-scrollback";
          };

          functions = {
            expand_named_dir = {
              argumentNames = [ "token" ];
              body =
                # fish
                ''
                  set -l name (string replace -r '^~([^/]+).*' '$1' -- $token)
                  set -l rest (string replace -r '^~[^/]+' "" -- $token)

                  switch $name
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (name: path: ''
                      case ${name}
                          echo "${path}$rest"'') namedDirs
                  )}
                  end
                '';
            };

            clear-screen-and-scrollback.body =
              # fish
              ''
                printf '\e[H\e[2J\e[3J'
                commandline -f repaint
              '';

            # Activate a .venv found at or above $PWD, deactivate on leaving it.
            auto_venv = {
              onVariable = "PWD";
              body =
                # fish
                ''
                  if set -q VIRTUAL_ENV
                      string match -q -- "$(path dirname $VIRTUAL_ENV)/*" "$PWD/"
                      or deactivate
                      return
                  end

                  set -l dir $PWD
                  while test "$dir" != /
                      if test -f $dir/.venv/bin/activate.fish
                          source $dir/.venv/bin/activate.fish
                          return
                      end

                      set dir (path dirname $dir)
                  end
                '';
            };

          }
          // lib.optionalAttrs config.programs.nix-index.enable {
            # nix-index ships no fish snippet, so drive nix-locate directly.
            fish_command_not_found.body =
              # fish
              ''
                set -l cmd $argv[1]
                set -l pkgs (${lib.getExe' config.programs.nix-index.package "nix-locate"} \
                    --minimal --no-group --type x --type s \
                    --whole-name --at-root "/bin/$cmd" 2>/dev/null)

                if test -z "$pkgs"
                    printf 'fish: Unknown command: %s\n' $cmd >&2
                    return 127
                end

                printf '%s is not installed. It is provided by:\n' $cmd >&2
                for p in $pkgs
                    printf '  nix shell nixpkgs#%s\n' (string replace -r '\.out$' "" -- $p) >&2
                end
              '';
          };

          interactiveShellInit =
            # fish
            ''
              set -g fish_greeting

              # `set -q` short-circuits, so on the host this is one variable test.
              if set -q CONTAINER_ID; and type -q pacman
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (
                  name: expansion: "    abbr --add ${name} ${lib.escapeShellArg expansion}"
                ) pacmanAbbrs
              )}
              end
            '';
        };
      };
    };
}
