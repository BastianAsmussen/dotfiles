{
  lib,
  osConfig,
  userInfo,
  inputs,
  pkgs,
  ...
}: {
  # If we're on Wayland, tell that to Firefox.
  home.sessionVariables = lib.mkIf osConfig.desktop.greeter.useWayland {
    MOZ_ENABLE_WAYLAND = "1";
  };

  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      ExtensionUpdate = false;
      ExtensionSettings = {
        "{8446b178-c865-4f5c-8ccc-1d7887811ae3}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3990315/catppuccin_mocha_lavender_git-2.0.xpi";
          installation_mode = "force_installed";
        };

        "uBlock0@raymondhill.net" = {
          install_url = "file:///${inputs.firefox-addons.packages.${pkgs.system}.ublock-origin}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/uBlock0@raymondhill.net.xpi";
          installation_mode = "force_installed";
        };
      };

      "3rdparty".Extensions."uBlock0@raymondhill.net" = import ./extensions/settings/ublock lib;

      DisablePocket = true;
      DisableFormHistory = false;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      AppAutoUpdate = false;
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "always";
      NoDefaultBookmarks = true;
      DisableSetDesktopBackground = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      PromptForDownloadLocation = true;
      FirefoxHome = {
        Search = true;
        Pocket = false;
        Snippets = false;
        TopSites = false;
        Highlights = false;
      };

      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
    };

    profiles.${userInfo.username} = {
      extensions = import ./extensions {inherit inputs pkgs;};
      bookmarks = import ./bookmarks.nix {};
      search = import ./search.nix pkgs;
      settings = import ./settings.nix {};
    };
  };
}
