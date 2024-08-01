{pkgs, ...}: {
  home.packages = with pkgs; [
    bc
  ];

  programs.zsh.initExtra = ''
    # Calculator.
    function = {
        if [[ -z "$1" ]]; then
            echo "Usage: calc <expression>"
            return 1
        fi

        # Check if bc is installed
        if ! command -v bc &> /dev/null; then
            echo "bc command is required but not installed."
            return 1
        fi

        result=$(echo "scale=10; $*" | bc -l 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Error: Invalid expression."
            return 1
        fi

        echo "$result"
    }
  '';
}
