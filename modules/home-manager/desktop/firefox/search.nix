pkgs: {
  default = "DuckDuckGo";
  force = true;

  engines = let
    hoursToSeconds = hours: hours * 60 * 60 * 1000;
    dayInSeconds = hoursToSeconds 24;
  in {
    "Nix Packages" = {
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];

      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = ["@np"];
    };

    "NixOS Wiki" = {
      urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = ["@nw"];
    };

    "Rust Documentation" = let
      baseUrl = "https://docs.rs";
    in {
      urls = [{template = "${baseUrl}/releases/search?query={searchTerms}";}];
      updateIconURL = "${baseUrl}/favicon.ico";
      # updateIterval = dayInSeconds;
      definedAliases = ["@rs" "@docs"];
    };

    "Cargo Crates" = let
      baseUrl = "https://crates.io";
    in {
      urls = [{template = "${baseUrl}/search?q={searchTerms}";}];
      updateIconURL = "${baseUrl}/favicon.ico";
      updateInterval = dayInSeconds;
      definedAliases = ["@crate" "@crates"];
    };

    "Urban Dictionary" = let
      baseUrl = "https://www.urbandictionary.com";
    in {
      urls = [{template = "${baseUrl}/define.php?term={searchTerms}";}];
      iconUpdateURL = "${baseUrl}/favicon-32x32.png";
      updateInterval = dayInSeconds;
      definedAliases = ["@urban"];
    };

    # Disable other search engines.
    "Google".metaData.hidden = true;
    "Bing".metaData.hidden = true;
    "Wikipedia (en)".metaData.hidden = true;
  };

  order = [
    "DuckDuckGo"
    "Nix Packages"
    "NixOS Wiki"
    "Cargo Crates"
    "Rust Documentation"
    "Urban Dictionary"
  ];
}
