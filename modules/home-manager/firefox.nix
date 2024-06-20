{
  config,
  pkgs,
  inputs,
  ...
}: {
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
    };
    
    profiles.bastian = {
      search.default = "DuckDuckGo";
      search.force = true;
      search.engines = {
        "Nix Packages" = {
          urls = [{
            template = "https://search.nixos.org/packages";
            params = [
              { name = "type"; value = "packages"; }
              { name = "query"; value = "{searchTerms}"; }
            ];
          }];
          
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@np"];
        };
        
        "NixOS Wiki" = {
           urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
           
           iconUpdateURL = "https://wiki.nixos.org/favicon.ico";
           updateInterval = 24 * 60 * 60 * 1000; # every day
           definedAliases = [ "@nw" ];
         };
         
        "Bing".metaData.hidden = true;
        "Google".metaData.hidden = true;
      };
      
      settings = {
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
      };
      
      extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
        bitwarden
        ublock-origin
        clearurls
        duckduckgo-privacy-essentials
        sponsorblock
        return-youtube-dislikes
        darkreader
      ];
    };
  };
}

