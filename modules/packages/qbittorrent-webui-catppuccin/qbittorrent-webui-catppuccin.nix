{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Catppuccin Mocha palette -> theme.css token substitution, done purely at
      # eval time so the build needs no extra tools.
      palette = lib.importJSON ./catppuccin-mocha.json;
      template = builtins.readFile ./theme.css.template;

      themeCss = builtins.replaceStrings (map (name: "%${name}%") (
        builtins.attrNames palette.colors
      )) (builtins.attrValues palette.colors) template;

      themeCssFile = pkgs.writeText "qbittorrent-webui-theme.css" themeCss;

      # Reuse the exact source the running qbittorrent-nox is built from so the
      # alternative WebUI always matches the served WebUI API. When nixpkgs bumps
      # qbittorrent, this tracks it automatically.
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

            # --replace-fail aborts the build if upstream changes these anchors,
            # surfacing a version mismatch instead of silently shipping an untheme'd UI.
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
