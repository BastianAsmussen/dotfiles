{ inputs, self, ... }:
{
  flake.homeModules.firefox =
    { lib, pkgs, ... }:
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
    in
    {
      imports = [ inputs.schizofox.homeManagerModules.default ];

      programs.schizofox = {
        enable = true;
        package = pkgs.firefox-esr-153-unwrapped;
        extensions = {
          enableDefaultExtensions = true;
          enableExtraExtensions = true;
          extraExtensions = mkExtensions (
            with addons;
            [
              gopass-bridge
              clearurls
              sponsorblock
              return-youtube-dislikes
              control-panel-for-youtube
              control-panel-for-twitter
            ]
          );
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

        # Disable sandboxing for extensions such as `gopass-bridge`.
        security.sandbox.enable = false;

        settings = {
          "browser.translations.automaticallyPopup" = false;
          "browser.display.use_system_colors" = true;
          "browser.nova.enabled" = false;
          "privacy.resistFingerprinting.letterboxing" = false;
          "general.autoScroll" = true;
        };

        # Schizofox uses outdated selectors for theming.
        theme.extraUserChrome =
          with self.theme;
          # css
          ''
            :root {
              --toolbar-background-color: ${base00} !important;
              --toolbar-text-color: ${base05} !important;
              --toolbar-field-background-color: ${base01} !important;
              --toolbar-field-background-color-focus: ${base01} !important;
              --toolbar-field-text-color: ${base05} !important;
              --toolbar-field-text-color-focus: ${base05} !important;
              --toolbar-field-border-color-focus: ${base0D} !important;
              --tab-background-color-selected: ${base00} !important;
              --tab-selected-textcolor: ${base05} !important;
              --panel-background-color: ${base00} !important;
              --panel-text-color: ${base05} !important;
              --panel-border-color: ${base03} !important;
              --urlbarview-background-color-selected: ${base02} !important;
              --urlbarview-text-color-selected: ${base05} !important;
            }

            .urlbarView-row[selected] {
              background-color: ${base02} !important;
              color: ${base05} !important;
            }
          '';

        theme.colors = with self.themeNoHash; {
          background-darker = base01;
          background = base00;
          foreground = base05;
          primary = base0D;
          border = base03;
        };
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

      # Profile, cookies, and the extensions' own storage.
      persistence.directories = [ ".mozilla" ];

      stylix.targets.firefox.enable = false;
    };
}
