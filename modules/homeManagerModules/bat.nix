{
  flake.homeModules.bat =
    {
      lib,
      pkgs,
      ...
    }:
    {
      home.shellAliases.cat = "${lib.getExe pkgs.bat} --plain --no-paging";

      programs.bat =
        let
          theme = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
            hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
          };
        in
        {
          enable = true;
          themes.catppuccin-mocha.src = "${theme}/themes/Catppuccin Mocha.tmTheme";
        };
    };
}
