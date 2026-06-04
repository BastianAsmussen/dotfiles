{ inputs, ... }:
{
  flake.homeModules.firefox =
    {
      config,
      osConfig,
      lib,
      ...
    }:
    {
      imports = [
        inputs.schizofox.homeManagerModule
      ];

      stylix.targets.firefox.enable = false;
      programs.schizofox = {
        enable = true;
        extensions = {
          enableDefaultExtensions = true;
          enableExtraExtensions = true;
          darkreader.enable = true;
          extraExtensions =
            let
              mkFirefoxURL = name: "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
            in
            {
              "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}".install_url = mkFirefoxURL "gopass-bridge";
              "{74145f27-f039-47ce-a470-a662b129930a}".install_url = mkFirefoxURL "clearurls";
              "sponsorBlocker@ajay.app".install_url = mkFirefoxURL "sponsorblock";
              "{762f9885-5a13-4abd-9c77-433dcd38b8fd}".install_url = mkFirefoxURL "return-youtube-dislikes";
              "moz-addon-prod@7tv.app".install_url = mkFirefoxURL "7tv-extension";
              "control-panel-for-youtube@jbscript.dev".install_url = mkFirefoxURL "control_panel_for_youtube";
              "control-panel-for-twitter@jbscript.dev".install_url = mkFirefoxURL "control_panel_for_twitter";
            };
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
          # sandbox, so it needs the gopass/gpg runtime paths bound in
          # or it can't decrypt and corrupts the native-messaging stream.
          extraBinds = [
            "${config.home.homeDirectory}/.gnupg" # keyring + trustdb
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
    };
}
