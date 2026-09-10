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
      # Use pinned rycee addons; update them with `nix flake update
      # firefox-addons`.
      addons = pkgs.firefox-addons;

      # Install signed addons under Firefox's application id using their addon
      # ids.
      firefoxAppId = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
      mkExtensions =
        pkgList:
        lib.listToAttrs (
          map (pkg: {
            name = pkg.addonId;
            value.install_url = "file://${pkg}/share/mozilla/extensions/${firefoxAppId}/${pkg.addonId}.xpi";
          }) pkgList
        );

      # Shim bwrap only for schizofox to give WebAuthn read-write YubiKey
      # access.
      sandboxPkgs = pkgs.extend (
        _: prev: {
          bubblewrap = prev.bubblewrap.overrideAttrs (old: {
            # Preserve bwrap metadata and mainProgram so lib.getExe still
            # resolves bin/bwrap.
            postInstall = (old.postInstall or "") + ''
              mv "$out/bin/bwrap" "$out/bin/.bwrap-real"

              cat > "$out/bin/bwrap" <<'SHIM'
              #!${prev.runtimeShell}
              set -eu

              real="$(dirname "$(readlink -f "$0")")/.bwrap-real"

              extra=()
              case "''${NIXPAK_APP_EXE:-}" in
                *schizofox*)
                  # Bind only Yubico hidraw nodes (vendor 1050), not keyboard or
                  # mouse HID.
                  for uevent in /sys/class/hidraw/hidraw*/device/uevent; do
                    [ -e "$uevent" ] || continue

                    if grep -qi '^HID_ID=.*:0\{0,4\}1050:' "$uevent"; then
                      node=''${uevent#/sys/class/hidraw/}
                      node=''${node%%/*}
                      extra+=( --dev-bind-try "/dev/$node" "/dev/$node" )
                    fi
                  done

                  # gopass-jsonapi needs writable .gnupg for gpg and scdaemon
                  # state.
                  extra+=( --bind-try "$HOME/.gnupg" "$HOME/.gnupg" )
                  ;;
              esac

              if [ ''${#extra[@]} -eq 0 ]; then
                exec "$real" "$@"
              fi

              # Insert mounts before the app command, after bwrap's --dev /dev.
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
        # Override pkgs only in schizofox's module argument set.
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

          # Bind gopass/gpg paths for the sandboxed native host; the shim
          # handles writable .gnupg.
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
