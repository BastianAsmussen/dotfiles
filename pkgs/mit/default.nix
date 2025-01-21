{
  pkgs,
  lib,
}: let
  licenseText = lib.strings.escape ["\""] (builtins.readFile ./license.txt);
in
  pkgs.writeShellScriptBin "mit" ''
    # @describe Generate an MIT license file.
    #
    # If any part of the script fails, the script will immediately terminate and
    # return the exit code of the failed command.
    # @meta version 0.1.0
    # @meta author Bastian Asmussen <bastian@asmussen.tech>
    # @flag -F --force Overwrite an existing LICENSE file.
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
            if [ -f "$backup_file" ]; then
              mv $backup_file $argc_file
            fi

            echo "Failed to write to $argc_file!"
            exit $exit_code
        fi

        # Remove backup file.
        if [ -f "$backup_file" ]; then
          rm $backup_file
        fi

        echo "Wrote MIT license to $argc_file."
    }

    eval "$(${lib.getExe pkgs.argc} --argc-eval "$0" "$@")"
  ''
