{ inputs, ... }:
{
  flake.homeModules.nixcord =
    { pkgs, ... }:
    {
      imports = [
        inputs.nixcord.homeModules.nixcord
      ];

      programs.nixcord = {
        enable = true;
        discord.enable = false;
        vesktop.enable = true;
        config = {
          themes."catppuccin-mocha" = pkgs.fetchurl {
            url = "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css";
            hash = "sha256-KVv9vfqI+WADn3w4yE1eNsmtm7PQq9ugKiSL3EOLheI=";
          };

          enabledThemes = [ "catppuccin-mocha.css" ];
          plugins = {
            callTimer.enable = true;
            dontRoundMyTimestamps.enable = true;
            noOnboardingDelay.enable = true;
            relationshipNotifier.enable = true;
            fakeNitro.enable = true;
            shikiCodeblocks =
              let
                theme = pkgs.fetchurl {
                  url = "https://cdn.jsdelivr.net/gh/shikijs/textmate-grammars-themes@bc5436518111d87ea58eb56d97b3f9bec30e6b83/packages/tm-themes/themes/catppuccin-mocha.json";
                  hash = "sha256-qgMNZ9vUprZplcibox75CsPC2iOjD3Eid6y1DG6U0QI=";
                };

                themeBase64 = pkgs.runCommandLocal "catppuccin-mocha-theme-base64" { } ''
                  ${pkgs.coreutils}/bin/base64 --wrap=0 ${theme} > "$out"
                '';
              in
              {
                enable = true;
                customTheme = "data:application/json;base64,${builtins.readFile themeBase64}";
              };
          };
        };

        extraConfig.IS_MAXIMISED = true;
      };

      stylix.targets.nixcord.enable = false;
    };
}
