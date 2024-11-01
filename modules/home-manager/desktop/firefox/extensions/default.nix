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
  don-t-fuck-with-paste
  istilldontcareaboutcookies
  duckduckgo-privacy-essentials
  return-youtube-dislikes
]
