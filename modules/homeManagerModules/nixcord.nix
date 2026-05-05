{inputs, ...}: {
  flake.homeModules.nixcord = {pkgs, ...}: {
    imports = [
      inputs.nixcord.homeModules.nixcord
    ];

    programs.nixcord = {
      enable = true;
      discord.enable = true;
      vesktop.enable = true;
      config = {
        themes."catppuccin-mocha" = pkgs.fetchurl {
          url = "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css";
          hash = "sha256-KVv9vfqI+WADn3w4yE1eNsmtm7PQq9ugKiSL3EOLheI=";
        };

        enabledThemes = ["catppuccin-mocha.css"];
        plugins = {
          callTimer.enable = true;
          dontRoundMyTimestamps.enable = true;
          friendsSince.enable = true;
          noOnboardingDelay.enable = true;
          relationshipNotifier.enable = true;
        };
      };

      extraConfig.IS_MAXIMISED = true;
    };

    stylix.targets.nixcord.enable = false;
  };
}
