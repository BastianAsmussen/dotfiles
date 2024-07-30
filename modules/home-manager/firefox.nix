{
  inputs,
  pkgs,
  lib,
  username,
  ...
}: let
  catppuccin-mocha-lavender-git = inputs.firefox-addons.lib.${pkgs.system}.buildFirefoxXpiAddon rec {
    pname = "catppuccin-mocha-lavender-git";
    version = "2.0";
    addonId = "{8446b178-c865-4f5c-8ccc-1d7887811ae3}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3990315/catppuccin_mocha_lavender_git-${version}.xpi";
    sha256 = "sha256-cCkrC4ZSy6tAjRXSYdxRUPaQ+1u6+W9OcxclbH2beTM=";
    meta = with lib; {
      homepage = "https://github.com/catppuccin/firefox";
      description = "🦊 Soothing pastel theme for Firefox";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in {
  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
    };

    profiles.${username} = {
      search = {
        default = "DuckDuckGo";
        force = true;

        engines = {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@np"];
          };

          "NixOS Wiki" = {
            urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];

            iconUpdateURL = "https://wiki.nixos.org/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000; # Once every day.
            definedAliases = ["@nw"];
          };

          # Disable other search engines.
          "Bing".metaData.hidden = true;
          "Google".metaData.hidden = true;
        };
      };

      settings = {
        "signon.rememberSignons" = false;
        "identity.fxaccounts.enabled" = false;
        "extensions.pocket.enabled" = false;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.donottrackheader.enabled" = true;

        # Auto-enable extensions.
        "extensions.autoDisableScopes" = 0;
      };

      bookmarks = [
        {
          name = "Mail";
          url = "https://mail.proton.me/u/0/inbox";
        }
        {
          name = "GitHub";
          url = "https://github.com";
        }
      ];

      extensions =
        (with inputs.firefox-addons.packages.${pkgs.system}; [
          bitwarden
          ublock-origin
          clearurls
          duckduckgo-privacy-essentials
          sponsorblock
          return-youtube-dislikes
          darkreader
          wayback-machine
          i-dont-care-about-cookies
        ])
        ++ [catppuccin-mocha-lavender-git];
    };
  };
}
