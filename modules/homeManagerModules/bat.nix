{
  flake.homeModules.bat =
    {
      lib,
      pkgs,
      ...
    }:
    {
      home.shellAliases.cat = "${lib.getExe pkgs.bat} --plain --no-paging";

      programs.bat = {
        enable = true;
        themes.catppuccin-mocha = builtins.readFile (
          pkgs.fetchurl {
            url = "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme";
            sha256 = "0xxashmrrj81y99ia4hvcpmplkzr1rlpgh4idf9inc7bikq6cm9r";
          }
        );
      };
    };
}
