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
    SCREENSHOTS="$HOME/Pictures/Screenshots"
    NOW=$(date +%Y-%m-%d_%H-%M-%S)
    TARGET="$SCREENSHOTS/$NOW.png"

    mkdir -p "$SCREENSHOTS"

    if [[ -n "$1" ]]; then
        ${wayshot} -f "$TARGET"
    else
        REGION=$(${slurp}) || exit 0
        ${wayshot} -f "$TARGET" -s "$REGION"
    fi

    # Verify the screenshot has a non-zero resolution.
    RES=$(${identify} -format "%w %h" "$TARGET" 2>/dev/null)
    WIDTH=$(echo "$RES" | cut -d' ' -f1)
    HEIGHT=$(echo "$RES" | cut -d' ' -f2)

    if [[ -z "$WIDTH" || -z "$HEIGHT" || "$WIDTH" -eq 0 || "$HEIGHT" -eq 0 ]]; then
        rm -f "$TARGET"
        exit 0
    fi

    ${wl-copy} < "$TARGET"

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
