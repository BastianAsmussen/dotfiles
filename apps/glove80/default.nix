{
  inputs,
  pkgs,
}: let
  # Combined U2F files from left- and right hands.
  firmware = import ./firmware.nix {inherit inputs pkgs;};
in
  pkgs.writeShellApplication {
    name = "flash";
    text = ''
      set +eu
      shopt -s nullglob

      RED='\033[0;31m'
      GREEN='\033[0;32m'
      NC='\033[0m'

      # Indent piped input 4 spaces.
      indent() { sed -e 's/^/    /'; }

      # Platform specific disk candidates.
      declare -a disks

      if [[ "$OSTYPE" == "linux-gnu"* ]]; then # GNU/Linux
        disks=(/run/media/"$(whoami)"/GLV80*)
      elif [[ "$OSTYPE" == "darwin"* ]]; then # macOS
        disks=(/Volumes/GLV80*)
      elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then # Cygwin/MSYS2
        disks=(/?)
      elif (grep -sq Microsoft /proc/version); then # WSL
        disks=(/mnt/?)
      else
        echo "''${RED}Unable to determine system platform!''${NC}"
        echo "''${RED}OS: $OSTYPE''${NC}"
        echo "''${RED}/proc/version:''${NC}"
        indent < /proc/version

        exit 1
      fi

      # Disks that have a matching `INFO_UF2`.
      declare -a matches
      for disk in "''${disks[@]}"; do
        if (grep -sq Glove80 "$disk"/INFO_UF2.TXT); then
          matches+=("$disk")
        fi
      done

      # Assert we found exactly one keyboard.
      count="''${#matches[@]}"
      if [[ "$count" -lt 1 ]]; then
        echo -e "''${RED}No Glove80 connected!''${NC}"
        exit 1
      elif [[ "$count" -gt 1 ]]; then
        echo -e "''${RED}$count Glove80s connected, expected exactly 1!''${NC}"
        for i in "''${!matches[@]}"; do
          kbd="''${matches[$i]}"

          echo "''${RED}$((i + 1)). $kbd"
          grep --no-filename --color=never Glove80 "$kbd"/INFO_UF2.TXT | indent
        done

        exit 1
      fi

      kbd="''${matches [0]}"
      echo -e "''${GREEN}Found keyboard:''${NC} $kbd"
      indent < "$kbd"/INFO_UF2.TXT
      echo

      read -rp "Proceed to flash firmware? [y/N] " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
      fi

      echo "Flashing firmware..."
      cp -r "${firmware}" "$kbd" \
        && echo -e "''${GREEN}Done!''${NC}" \
        || echo -e "''${RED}Unable to flash firmware!''${NC}"
    '';
  }
