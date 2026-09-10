{ inputs, ... }:
{
  flake.homeModules.firefox =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      # Version-pinned, hash-locked xpis from the rycee firefox-addons set
      # (overlay registered in overlays.nix). Bump them all declaratively with
      # `nix flake update firefox-addons`.
      addons = pkgs.firefox-addons;

      # Firefox installs system extensions under its application id; each addon
      # package drops its signed xpi there named by its own addon id.
      firefoxAppId = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
      mkExtensions =
        pkgList:
        lib.listToAttrs (
          map (pkg: {
            name = pkg.addonId;
            value.install_url = "file://${pkg}/share/mozilla/extensions/${firefoxAppId}/${pkg.addonId}.xpi";
          }) pkgList
        );

      # Schizofox sandboxes Firefox with NixPak, whose bwrap arguments are baked
      # into the launcher at build time. That sandbox mounts a fresh, empty
      # devtmpfs over /dev and binds exactly one device (/dev/dri), so WebAuthn
      # can never reach the YubiKey: Firefox opens /dev/hidraw* directly and
      # needs it read-write. `security.sandbox.extraBinds` cannot help; it maps
      # to --ro-bind, and a read-only bind of a character device fails that
      # O_RDWR. Upstream exposes no device-bind, read-write-bind or raw
      # bubblewrap option, and its mkNixPak call is a closed literal.
      #
      # NixPak reads `bubblewrap.package` from whatever pkgs it is handed and
      # never overrides it, so shimming bwrap is the one seam left.
      #
      # Scoped to this import on purpose. `nix.nix` applies every entry of
      # flake.overlays to every host, so overriding pkgs.bubblewrap there would
      # rebuild webkitgtk, flatpak, bottles and steam-run on each nixpkgs bump,
      # for a need that is only ever schizofox's.
      sandboxPkgs = pkgs.extend (
        _: prev: {
          bubblewrap = prev.bubblewrap.overrideAttrs (old: {
            # overrideAttrs rather than a symlinkJoin: this keeps pname, version,
            # passthru and meta.mainProgram, so consumers that resolve the binary
            # through `lib.getExe` still find bin/bwrap.
            postInstall = (old.postInstall or "") + ''
              mv "$out/bin/bwrap" "$out/bin/.bwrap-real"

              cat > "$out/bin/bwrap" <<'SHIM'
              #!${prev.runtimeShell}
              set -eu

              real="$(dirname "$(readlink -f "$0")")/.bwrap-real"

              extra=()
              case "''${NIXPAK_APP_EXE:-}" in
                *schizofox*)
                  # Only the token's own nodes. Binding every /dev/hidraw* would
                  # hand the sandbox the keyboard and mouse HID devices as well,
                  # which is a keylogging surface inside the thing meant to
                  # prevent one. 1050 is Yubico's USB vendor id.
                  for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
                    [ -e "$uevent" ] || continue

                    if grep -qi '^HID_ID=.*:0\{0,4\}1050:' "$uevent"; then
                      node=''${uevent#/sys/class/hidraw/}
                      node=''${node%%/*}
                      extra+=( --dev-bind-try "/dev/$node" "/dev/$node" )
                    fi
                  done

                  # gopass-jsonapi runs inside the sandbox, so gpg and scdaemon
                  # need to write here: lock files, random_seed, and the shadow
                  # keys a smartcard operation creates. Schizofox binds it
                  # read-only.
                  extra+=( --bind-try "$HOME/.gnupg" "$HOME/.gnupg" )
                  ;;
              esac

              if [ ''${#extra[@]} -eq 0 ]; then
                exec "$real" "$@"
              fi

              # bwrap applies mounts in argv order and the app command follows a
              # bare `--`, so inserting there lands after the --dev /dev that
              # would otherwise shadow these.
              args=()
              inserted=0
              for arg in "$@"; do
                if [ "$inserted" -eq 0 ] && [ "$arg" = "--" ]; then
                  args+=( "''${extra[@]}" )
                  inserted=1
                fi

                args+=( "$arg" )
              done

              [ "$inserted" -eq 1 ] || args+=( "''${extra[@]}" )
              exec "$real" "''${args[@]}"
              SHIM

              chmod +x "$out/bin/bwrap"
            '';
          });
        }
      );
    in
    {
      imports = [
        # A lambda with no formals receives the whole module-argument set, so
        # this shadows pkgs for schizofox alone and leaves every other module
        # (and the global package set) on the stock bubblewrap.
        (args: inputs.schizofox.homeManagerModule (args // { pkgs = sandboxPkgs; }))
      ];

      stylix.targets.firefox.enable = false;
      programs.schizofox = {
        enable = true;
        extensions = {
          enableDefaultExtensions = true;
          enableExtraExtensions = true;
          darkreader.enable = true;
          extraExtensions = mkExtensions [
            addons.gopass-bridge
            addons.clearurls
            addons.sponsorblock
            addons.return-youtube-dislikes
            # addons."7tv"
            addons.control-panel-for-youtube
            addons.control-panel-for-twitter
          ];
        };

        misc = {
          drm.enable = true;
          disableWebgl = false;
          contextMenu.enable = true;
          displayBookmarksInToolbar = "always";
          bookmarks = [
            {
              Title = "Mail";
              URL = "https://mail.proton.me/u/0";
              Placement = "toolbar";
              Folder = "Proton";
            }
            {
              Title = "Drive";
              URL = "https://drive.proton.me/u/0";
              Placement = "toolbar";
              Folder = "Proton";
            }
            {
              Title = "Codeberg.org";
              URL = "https://codeberg.org";
              Placement = "toolbar";
              Folder = "VCS";
            }
            {
              Title = "GitHub";
              URL = "https://github.com";
              Placement = "toolbar";
              Folder = "VCS";
            }
          ];
        };

        search = {
          defaultSearchEngine = "Kagi";
          addEngines = [
            {
              Name = "Kagi";
              Description = "Kagi Search";
              Alias = "!k";
              Method = "GET";
              URLTemplate = "https://kagi.com/search?q={searchTerms}";
            }
          ];

          removeEngines = [
            "Google"
            "Bing"
            "Brave"
            "Perplexity"
            "Amazon.com"
            "eBay"
            "Twitter"
            "Wikipedia"
          ];
        };

        settings = {
          "browser.translations.automaticallyPopup" = false;
          "browser.display.use_system_colors" = true;
          "privacy.resistFingerprinting.letterboxing" = false;
          "general.autoScroll" = true;
        };

        security.sandbox = {
          enable = true;

          # gopassbridge's native host (gopass-jsonapi) runs *inside* this
          # sandbox, so it needs the gopass/gpg runtime paths bound in or it
          # can't decrypt and corrupts the native-messaging stream.
          #
          # ~/.gnupg is deliberately absent: these are all --ro-bind, and gpg
          # needs to write there (lock files, random_seed, shadow keys). The
          # bwrap shim in overlays.nix binds it read-write instead, alongside
          # the YubiKey's hidraw nodes.
          extraBinds = [
            "${config.home.homeDirectory}/.password-store" # the secrets
            "${config.home.homeDirectory}/.config/gopass" # gopass config
            "/run/user/1000/gnupg" # gpg-agent socket
          ];
        };

        theme = lib.optionalAttrs (osConfig != null) (
          let
            inherit (osConfig.lib.stylix) colors;
          in
          {
            colors = {
              background-darker = colors.base01;
              background = colors.base00;
              foreground = colors.base05;
            };
          }
        );
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications =
          let
            browser = "Schizofox.desktop";
          in
          {
            "text/html" = browser;
            "application/pdf" = browser;
            "x-scheme-handler/http" = browser;
            "x-scheme-handler/https" = browser;
            "x-scheme-handler/about" = browser;
            "x-scheme-handler/unknown" = browser;
          };
      };

      persistence.directories = [
        # Profile, cookies, and the extensions' own storage.
        ".mozilla"
      ];
    };
}
