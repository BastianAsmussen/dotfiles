{
  lib,
  pkgs,
}: let
  inherit (lib) getExe;

  notify-send = getExe pkgs.libnotify;
  slurp = getExe pkgs.slurp;
  wayshot = getExe pkgs.wayshot;
  swappy = getExe pkgs.swappy;
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
  identify = "${pkgs.imagemagick}/bin/identify";
in
  pkgs.writeShellScriptBin "screenshot" ''
    set -euo pipefail

    SCREENSHOTS="$HOME/Pictures/Screenshots"
    LOCKFILE="$SCREENSHOTS/.screenshot.lock"

    mkdir -p "$SCREENSHOTS"

    # If a lock file exists, check if the owning process is still alive.
    if [[ -f "$LOCKFILE" ]]; then
      LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null || true)

      if [[ -n "$LOCK_PID" ]] && kill -0 "$LOCK_PID" 2>/dev/null; then
        exit 0 # Still running, bail out.
      fi

      # Stale lock, remove it.
      rm -f "$LOCKFILE"
    fi

    echo "$$" > "$LOCKFILE"
    cleanup() {
      rm -f "$LOCKFILE"
    }

    trap cleanup EXIT INT TERM

    NOW=$(date +%Y-%m-%d_%H-%M-%S)
    TARGET="$SCREENSHOTS/$NOW.png"

    if [[ -n "''${1-}" ]]; then
      ${wayshot} -f "$TARGET"
    else
      REGION=$(${slurp}) || exit 0
      ${wayshot} -f "$TARGET" -s "$REGION"
    fi

    # Verify the screenshot has a non-zero resolution.
    RES=$(${identify} -format "%w %h" "$TARGET" 2>/dev/null || true)
    WIDTH=$(echo "$RES" | cut -d' ' -f1)
    HEIGHT=$(echo "$RES" | cut -d' ' -f2)

    if [[ -z "$WIDTH" || -z "$HEIGHT" || "$WIDTH" -eq 0 || "$HEIGHT" -eq 0 ]]; then
      rm -f "$TARGET"
      exit 0
    fi

    ${wl-copy} < "$TARGET"

    # Remove the lock before blocking on the notification.
    rm -f "$LOCKFILE"

    ACTION=$(${notify-send} \
      -a "Screenshot" \
      -i "image-x-generic-symbolic" \
      -h "string:image-path:$TARGET" \
      -A "file=Show in Files" \
      -A "view=View" \
      -A "edit=Edit" \
      "Screenshot Taken" \
      "$TARGET")

    case "$ACTION" in
      "file") xdg-open "$SCREENSHOTS" ;;
      "view") xdg-open "$TARGET" ;;
      "edit") ${swappy} -f "$TARGET" ;;
      *) ;;
    esac
  ''
