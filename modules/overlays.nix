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

      # Schizofox sandboxes Firefox with NixPak, whose bwrap arguments are baked
      # into the launcher at build time. The sandbox mounts a fresh, empty
      # devtmpfs over /dev and binds exactly one device (/dev/dri), so WebAuthn
      # cannot reach the YubiKey: Firefox opens /dev/hidraw* directly and needs
      # it read-write. Schizofox exposes only `extraBinds`, which is --ro-bind,
      # and a read-only bind of a character device fails that O_RDWR. Upstream
      # has no device-bind, read-write-bind or raw-bubblewrap option, and its
      # mkNixPak call is a closed literal.
      #
      # NixPak does take `bubblewrap.package` from pkgs and never overrides it,
      # so wrapping bwrap is the one seam left. The shim is inert for every
      # other caller.
      #
      # Coupled to NixPak internals: the launcher sets NIXPAK_APP_EXE, does not
      # pass --clearenv, and launcher/bubblewrap.go always appends a bare `--`
      # before the app command. Re-check all three on a schizofox bump.
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
              # Only the token's own nodes. Binding every /dev/hidraw* would
              # hand the sandbox the keyboard and mouse HID devices as well,
              # which is a keylogging surface inside the thing meant to prevent
              # one. 1050 is Yubico's USB vendor id.
              for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
                [ -e "\$uevent" ] || continue

                if grep -qi '^HID_ID=.*:0\{0,4\}1050:' "\$uevent"; then
                  node=\''${uevent#/sys/class/hidraw/}
                  node=\''${node%%/*}
                  extra+=( --dev-bind-try "/dev/\$node" "/dev/\$node" )
                fi
              done

              # gopass-jsonapi runs inside the sandbox, so gpg and scdaemon need
              # to write here: lock files, random_seed, and the shadow keys a
              # smartcard operation creates. Schizofox binds it read-only.
              extra+=( --bind-try "\$HOME/.gnupg" "\$HOME/.gnupg" )
              ;;
          esac

          if [ \''${#extra[@]} -eq 0 ]; then
            exec ${prev.bubblewrap}/bin/bwrap "\$@"
          fi

          # bwrap applies mounts in argv order and the app command follows a
          # bare \`--\`, so inserting there lands after the --dev /dev that would
          # otherwise shadow these.
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

      # Two upstream bugs in `fish.completion`: `test -a` was removed in fish 4,
      # and `PROG` is set without `-g`, so it is out of scope by the time the
      # completion function runs.
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
