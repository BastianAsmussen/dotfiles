{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Substitute Catppuccin Mocha tokens at eval time without extra build
      # tools.
      palette = lib.importJSON ./catppuccin-mocha.json;
      template = builtins.readFile ./theme.css.template;

      themeCss = builtins.replaceStrings (map (name: "%${name}%") (
        builtins.attrNames palette.colors
      )) (builtins.attrValues palette.colors) template;

      themeCssFile = pkgs.writeText "qbittorrent-webui-theme.css" themeCss;

      # Use qBittorrent's own source so the alternative WebUI matches its API.
      qbittorrent = pkgs.qbittorrent-nox;
    in
    {
      packages.qbittorrent-webui-catppuccin =
        pkgs.runCommandLocal "qbittorrent-webui-catppuccin-mocha-${qbittorrent.version}"
          {
            inherit (qbittorrent) src;

            meta = {
              description = "Catppuccin Mocha alternative WebUI for qBittorrent ${qbittorrent.version}";
              homepage = "https://github.com/catppuccin/qbittorrent";
              license = lib.licenses.mit;
              platforms = lib.platforms.all;
            };
          }
          ''
            cp -r "$src/src/webui/www" "$out"
            chmod -R u+w "$out"

            # Overlay the generated theme, loaded last so it overrides the stock CSS.
            install -Dm644 ${themeCssFile} "$out/private/css/theme.css"
            install -Dm644 ${themeCssFile} "$out/public/css/theme.css"

            # Fail the build when upstream changes the substitution anchors.
            substituteInPlace "$out/private/index.html" \
              --replace-fail \
                '<link rel="stylesheet" type="text/css" href="css/Tabs.css?v=''${CACHEID}">' \
                '<link rel="stylesheet" type="text/css" href="css/Tabs.css?v=''${CACHEID}"><link rel="stylesheet" type="text/css" href="css/theme.css?v=''${CACHEID}">'

            substituteInPlace "$out/public/index.html" \
              --replace-fail \
                '<link rel="stylesheet" type="text/css" href="css/login.css?v=''${CACHEID}">' \
                '<link rel="stylesheet" type="text/css" href="css/login.css?v=''${CACHEID}"><link rel="stylesheet" type="text/css" href="css/theme.css?v=''${CACHEID}">'
          '';
    };
}
