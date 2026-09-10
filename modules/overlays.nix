{
  withSystem,
  inputs,
  ...
}:
{
  flake.overlays = {
    # Bring our custom packages into scope.
    additions =
      _: prev:
      withSystem prev.stdenv.hostPlatform.system (
        { config, ... }:
        {
          inherit (config.packages)
            deepseek-harness
            mit
            qbittorrent-webui-catppuccin
            worldmonitor
            worldmonitor-relay
            worldmonitor-redis-rest
            absolute-episode
            calculator
            copy-file
            neovim
            neovim-minimal
            repo-cloner
            ;
        }
      );

    # Version-pinned, hash-locked Firefox addons (`pkgs.firefox-addons.*`).
    firefox-addons = inputs.firefox-addons.overlays.default;

    # User-defined overlays.
    modifications = _: prev: {
      bottles = prev.bottles.override {
        removeWarningPopup = true;
      };

      # Shim bwrap for writable YubiKey access; re-check NixPak launcher
      # assumptions on upgrades.
      bubblewrap = prev.symlinkJoin {
        name = "bubblewrap-schizofox-devices";
        paths = [ prev.bubblewrap ];
        postBuild = ''
          rm "$out/bin/bwrap"

          cat > "$out/bin/bwrap" <<SHIM
          #!${prev.runtimeShell}
          set -eu

          extra=()
          case "\''${NIXPAK_APP_EXE:-}" in
            *schizofox*)
              # Bind only Yubico hidraw nodes (vendor 1050), not keyboard or
              # mouse HID.
              for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
                [ -e "\$uevent" ] || continue

                if grep -qi '^HID_ID=.*:0\{0,4\}1050:' "\$uevent"; then
                  node=\''${uevent#/sys/class/hidraw/}
                  node=\''${node%%/*}
                  extra+=( --dev-bind-try "/dev/\$node" "/dev/\$node" )
                fi
              done

              # gopass-jsonapi needs writable .gnupg for gpg and scdaemon state.
              extra+=( --bind-try "\$HOME/.gnupg" "\$HOME/.gnupg" )
              ;;
          esac

          if [ \''${#extra[@]} -eq 0 ]; then
            exec ${prev.bubblewrap}/bin/bwrap "\$@"
          fi

          # Insert mounts before the app command, after bwrap's --dev /dev.
          args=()
          inserted=0
          for arg in "\$@"; do
            if [ "\$inserted" -eq 0 ] && [ "\$arg" = "--" ]; then
              args+=( "\''${extra[@]}" )
              inserted=1
            fi

            args+=( "\$arg" )
          done

          [ "\$inserted" -eq 1 ] || args+=( "\''${extra[@]}" )
          exec ${prev.bubblewrap}/bin/bwrap "\''${args[@]}"
          SHIM

          chmod +x "$out/bin/bwrap"
        '';
      };

      # Fix fish 4's removed `test -a` and make PROG global for completions.
      gopass = prev.gopass.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          +
          # fish
          ''
            substituteInPlace fish.completion \
              --replace-fail '[ (count $cmd) -eq 1 -a $cmd[1] = $PROG ]' \
                '[ (count $cmd) -eq 1 ]; and [ "$cmd[1]" = gopass ]'
          '';
      });
    };

    # Convenient access to the nixpkgs stable branch.
    stable-packages = _: prev: {
      stable = withSystem prev.stdenv.hostPlatform.system (
        import inputs.nixpkgs-stable {
          config.allowUnfree = true;
        }
      );
    };
  };
}
