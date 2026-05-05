{inputs, ...}: {
  flake.homeModules.firefox = {
    osConfig,
    lib,
    ...
  }: {
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
        extraExtensions = let
          mkFirefoxURL = name: "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
        in {
          "{74145f27-f039-47ce-a470-a662b129930a}".install_url = mkFirefoxURL "clearurls";
          "sponsorBlocker@ajay.app".install_url = mkFirefoxURL "sponsorblock";
          "{762f9885-5a13-4abd-9c77-433dcd38b8fd}".install_url = mkFirefoxURL "return-youtube-dislikes";
          "{34daeb50-c2d2-4f14-886a-7160b24d66a4}".install_url = mkFirefoxURL "youtube-shorts-block";
          "moz-addon-prod@7tv.app".install_url = mkFirefoxURL "7tv-extension";
          "control-panel-for-youtube@jbscript.dev".install_url = mkFirefoxURL "control_panel_for_youtube";
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
            Title = "GitHub";
            URL = "https://github.com";
            Placement = "toolbar";
          }
        ];
      };

      search.defaultSearchEngine = "DuckDuckGo";
      settings = {
        "browser.translations.automaticallyPopup" = false;
        "browser.display.use_system_colors" = true;
        "privacy.resistFingerprinting.letterboxing" = false;
        "general.autoScroll" = true;
      };

      security.sandbox.enable = true;
      theme = lib.optionalAttrs (osConfig != null) (let
        inherit (osConfig.lib.stylix) colors;
      in {
        colors = {
          background-darker = colors.base01;
          background = colors.base00;
          foreground = colors.base05;
        };
      });
    };
  };
}
