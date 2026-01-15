{
  enableDefaultExtensions = true;
  enableExtraExtensions = true;

  darkreader.enable = true;

  extraExtensions = let
    mkFirefoxURL = name: "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
  in {
    "{446900e4-71c2-419f-a6a7-df9c091e268b}".install_url = mkFirefoxURL "bitwarden-password-manager";
    "{74145f27-f039-47ce-a470-a662b129930a}".install_url = mkFirefoxURL "clearurls";
    "sponsorBlocker@ajay.app".install_url = mkFirefoxURL "sponsorblock";
    "{762f9885-5a13-4abd-9c77-433dcd38b8fd}".install_url = mkFirefoxURL "return-youtube-dislikes";
    "{34daeb50-c2d2-4f14-886a-7160b24d66a4}".install_url = mkFirefoxURL "youtube-shorts-block";
  };
}
