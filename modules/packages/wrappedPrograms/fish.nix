{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    fishConf =
      pkgs.writeText "config.fish"
      # fish
      ''
        function fish_prompt
            string join "" -- (set_color red) "[" (set_color yellow) $USER (set_color green) "@" (set_color blue) $hostname (set_color magenta) " " $(prompt_pwd) (set_color red) ']' (set_color normal) "\$ "
        end

        set fish_greeting
        fish_vi_key_bindings

        zoxide init fish | source

        function lf --wraps="lf" --description="lf - Terminal file manager (changing directory on exit)"
            cd "$(command lf -print-last-dir $argv)"
        end

        function myip "Get your public IPv4 address"
            curl -s https://ifconfig.me/ -w '\n'
        end

        function system-size "Calculates the size of the current system derivation"
            nix path-info -Sh /run/current-system | tail -1 | awk '{ print $2, $3 }';
        end

        function mkdir -d "Create a directory and set CWD"
            command mkdir $argv

            if test $status = 0
                switch $argv[(count $argv)]
                    case '-*'

                    case '*'
                        cd $argv[(count $argv)]

                        return
                end
            end
        end

        # Shortcut functions.
        function c
            clear
        end

        function cat
            bat --plain
        end

        function tree
            eza --tree
        end

        function cd..
            cd ..
        end

        function rgf "Search by file names"
            rg --files | rg
        end

        function cp
            cp -r $argv
        end

        function rm
            rm -r $argv
        end

        function mkdir
            mkdir -p $argv
        end

        function neofetch
            fastfetch
        end
      '';
  in {
    packages.fish = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;

      package = pkgs.fish;
      runtimeInputs = with pkgs; [
        zoxide
        bat
        eza
        ripgrep
        fastfetch
      ];

      flags."-C" = "source ${fishConf}";
    };
  };
}
