{
  inputs,
  pkgs,
}:
with inputs.firefox-addons.packages.${pkgs.system}; [
  bitwarden
  darkreader
  sponsorblock
  youtube-shorts-block
  clearurls
  privacy-badger
  skip-redirect
  istilldontcareaboutcookies
  duckduckgo-privacy-essentials
  return-youtube-dislikes
]
