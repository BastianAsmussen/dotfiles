{
  pkgs,
  lib,
}: let
  licenseText = lib.strings.escape ["\""] (builtins.readFile ./license.txt);
in
  pkgs.writeShellScriptBin "mit" ''
    # @describe                        Generate an MIT license file.
    # @flag   -F --force               Overwrite an existing LICENSE file.
    # @option -f --file=LICENSE <FILE> The file to write to.

    main() {
        backup_file="LICENSE.bak"
        if [ -f "$argc_file" ]; then
            if [ ! $argc_force ]; then
                echo "$argc_file already exists, re-run with -F to overwrite it!"
                exit 1
            fi

            # For restoration if it fails.
            mv $argc_file $backup_file
        fi

        current_year=$(date +%Y)
        full_name=$(getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1)

        set -o noclobber
        echo "${licenseText}" >| $argc_file

        sed -i \
          -e "s/\[year\]/$current_year/g" \
          -e "s/\[fullname\]/$full_name/g" \
          $argc_file
        exit_code=$?

        if [ $exit_code -gt 0 ]; then
            # Restore the original file.
            mv $backup_file $argc_file

            echo "Failed to write to $argc_file!"
            exit $exit_code
        fi

        # Remove backup file.
        rm $backup_file

        echo "Wrote MIT license to $argc_file."
    }

    eval "$(${lib.getExe pkgs.argc} --argc-eval "$0" "$@")"
  ''
