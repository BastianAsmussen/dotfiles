{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      config,
      ...
    }:
    let
      # Build against MoErgo's own pinned nixpkgs, as the Layout Editor does.
      zmk = import inputs.glove80-zmk {
        pkgs = import "${inputs.glove80-zmk}/nix/pinned-nixpkgs.nix" { inherit system; };
      };

      half =
        board:
        zmk.zmk.override {
          inherit board;
          keymap = ./glove80.keymap;
        };
    in
    {
      packages = {
        glove80-firmware = zmk.combine_uf2 (half "glove80_lh") (half "glove80_rh") "glove80" // {
          meta = {
            description = "Combined Glove80 ZMK firmware image for both halves.";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.BastianAsmussen ];
            platforms = lib.platforms.linux;
          };
        };

        glove80-flash = pkgs.writeShellApplication {
          name = "glove80-flash";
          runtimeInputs = with pkgs; [
            coreutils
            util-linux
          ];

          text = ''
            firmware=${config.packages.glove80-firmware}/glove80.uf2

            halves=("$@")
            if [ ''${#halves[@]} -eq 0 ]; then
              halves=(lh rh)
            fi

            for half in "''${halves[@]}"; do
              case "$half" in
                lh | rh) ;;
                *)
                  echo "Unknown half '$half', expected 'lh' or 'rh'." >&2
                  exit 1
                  ;;
              esac
            done

            for half in "''${halves[@]}"; do
              side=left
              [ "$half" = rh ] && side=right
              dev="/dev/disk/by-label/GLV80''${half^^}BOOT"

              echo "Put the $side half in bootloader mode..."
              until [ -e "$dev" ]; do sleep 1; done

              mnt="$(mktemp -d)"
              sudo mount "$dev" "$mnt"
              sudo cp "$firmware" "$mnt/"
              sync

              # The half reboots as soon as the image lands, which can fail the unmount.
              sudo umount "$mnt" 2> /dev/null || sudo umount --lazy "$mnt" 2> /dev/null || true
              until [ ! -e "$dev" ]; do sleep 1; done
              rmdir "$mnt"

              echo "Flashed the $side half."
            done
          '';

          meta = {
            description = "Flash the Glove80 firmware onto each half in bootloader mode.";
            license = lib.licenses.mit;
            maintainers = [ lib.maintainers.BastianAsmussen ];
            platforms = lib.platforms.linux;
            mainProgram = "glove80-flash";
          };
        };
      };
    };
}
