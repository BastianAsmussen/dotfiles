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
      # Bump these declaratively with `nix flake update firefox-addons`.
      addons = pkgs.firefox-addons;

      # Firefox reads system extensions from under its own application id.
      firefoxAppId = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
      mkExtensions =
        pkgList:
        lib.listToAttrs (
          map (pkg: {
            name = pkg.addonId;
            value.install_url = "file://${pkg}/share/mozilla/extensions/${firefoxAppId}/${pkg.addonId}.xpi";
          }) pkgList
        );

      # Nixpak's mkNixPak call is a closed literal; bubblewrap.package is the seam.
      sandboxPkgs = pkgs.extend (
        _: prev: {
          bubblewrap = prev.bubblewrap.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              mv "$out/bin/bwrap" "$out/bin/.bwrap-real"

              cat > "$out/bin/bwrap" <<'SHIM'
              #!${prev.runtimeShell}
              set -eu

              real="$(dirname "$(readlink -f "$0")")/.bwrap-real"

              extra=()
              case "''${NIXPAK_APP_EXE:-}" in
                *schizofox*)
                  # Firefox enumerates FIDO tokens with libudev, which needs both.
                  extra+=( --ro-bind-try /sys/class/hidraw /sys/class/hidraw )
                  extra+=( --ro-bind-try /run/udev /run/udev )

                  # gpg and scdaemon write here; schizofox binds it read-only.
                  extra+=( --bind-try "$HOME/.gnupg" "$HOME/.gnupg" )
                  ;;
              esac

              if [ ''${#extra[@]} -eq 0 ]; then
                exec "$real" "$@"
              fi

              args=()
              inserted=0
              swap=0
              for arg in "$@"; do
                # udev adds tokens to this after launch; bwrap's own /dev is nodev.
                if [ "$swap" -eq 1 ]; then
                  swap=0
                  args+=( --dev-bind /run/schizofox-dev "$arg" )
                  continue
                fi

                if [ "$arg" = "--dev" ]; then
                  swap=1
                  continue
                fi

                # bwrap applies mounts in argv order and the app follows a bare --.
                if [ "$inserted" -eq 0 ] && [ "$arg" = "--" ]; then
                  args+=( "''${extra[@]}" )
                  inserted=1
                fi

                args+=( "$arg" )
              done

              # Nixpak runs xdg-dbus-proxy through this same bwrap, separator-less.
              [ "$inserted" -eq 1 ] || exec "$real" "$@"
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
        # A formals-free lambda takes the whole argument set, shadowing pkgs here only.
        (args: inputs.schizofox.homeManagerModules.default (args // { pkgs = sandboxPkgs; }))
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

          # gopass-jsonapi runs inside the sandbox and decrypts from these paths.
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
