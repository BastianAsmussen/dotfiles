{
  pkgs,
  inputs,
  username,
  ...
}: {
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

      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
        bitwarden
        ublock-origin
        clearurls
        duckduckgo-privacy-essentials
        sponsorblock
        return-youtube-dislikes
        darkreader
        wayback-machine
        i-dont-care-about-cookies
      ];
    };
  };
}
