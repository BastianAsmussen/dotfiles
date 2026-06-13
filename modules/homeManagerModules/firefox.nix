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
    in
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
          extraExtensions = mkExtensions [
            addons.gopass-bridge
            addons.clearurls
            addons.sponsorblock
            addons.return-youtube-dislikes
            addons."7tv"
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
