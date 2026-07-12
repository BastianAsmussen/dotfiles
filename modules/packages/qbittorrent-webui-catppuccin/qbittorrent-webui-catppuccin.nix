{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (self) theme;

      # Semantic WebUI tokens collapsed onto the stylix base16 palette
      # (self.theme) so this tracks the active scheme instead of pinning hexes.
      # base16 has no slot below base00 and lacks mantle/crust/surface2/overlay1/
      # sapphire/sky/maroon, so those fold to the nearest slot: the sub-base00
      # darks flatten toward base00/base01 (some background depth is lost),
      # surface2->base02, overlay1->base03, sky->base0C, maroon->base08,
      # sapphire->base0D.
      colors = {
        BG_PRIMARY = theme.base00; # base
        BG_SECONDARY = theme.base01; # surface0
        BG_ALTERNATE = theme.base00; # mantle
        BG_HOVER = theme.base02; # surface1
        BG_SELECTED = theme.base02; # surface1
        BG_TABLE = theme.base00; # mantle
        BG_HEADER = theme.base00; # mantle
        BG_PROGRESS = theme.base01; # crust (lightened to keep the track visible)
        BG_LIGHT = theme.base02; # surface2
        BG_MIDLIGHT = theme.base02; # surface1
        BG_MID = theme.base01; # surface0
        BG_DARK = theme.base01; # crust

        FG_PRIMARY = theme.base05; # text
        FG_BRIGHT = theme.base06; # rosewater
        FG_DISABLED = theme.base03; # overlay1

        BORDER = theme.base02; # surface1
        ACCENT = theme.base0D; # blue
        ACCENT_DIM = theme.base0D; # sapphire

        STATUS_DOWNLOADING = theme.base0B; # green
        STATUS_UPLOADING = theme.base0D; # blue
        STATUS_STALLED = theme.base0A; # yellow
        STATUS_PAUSED = theme.base03; # overlay1
        STATUS_ERROR = theme.base08; # red
        STATUS_QUEUED = theme.base0C; # sky

        LOG_TIME = theme.base03; # overlay1
        LOG_NORMAL = theme.base05; # text
        LOG_INFO = theme.base0C; # sky
        LOG_WARNING = theme.base09; # peach
        LOG_CRITICAL = theme.base08; # red
        LOG_BANNED = theme.base08; # maroon

        BUTTON_BG = theme.base01; # surface0
        BUTTON_FG = theme.base05; # text
        BUTTON_BORDER = theme.base02; # surface1
        BUTTON_BG_HOVER = theme.base02; # surface1
        BUTTON_BORDER_HOVER = theme.base02; # surface2
        BUTTON_BG_PRESSED = theme.base00; # mantle
        BUTTON_BORDER_PRESSED = theme.base03; # overlay0
        BUTTON_BG_DISABLED = theme.base01; # surface0
        BUTTON_FG_DISABLED = theme.base03; # overlay0

        TAB_BG = theme.base00; # mantle
        TAB_BG_HOVER = theme.base01; # surface0
        TAB_BG_SELECTED = theme.base00; # base
        TAB_BORDER = theme.base01; # surface0
        TAB_INDICATOR = theme.base0D; # blue

        SIDEBAR_BG = theme.base00; # mantle
        SIDEBAR_FG = theme.base05; # text
        SIDEBAR_BORDER = theme.base01; # surface0
        SIDEBAR_HOVER_BG = theme.base01; # surface0
        SIDEBAR_SELECTED_BG = theme.base02; # surface1
        SIDEBAR_SELECTED_INDICATOR = theme.base0D; # blue

        CHECK_BG = theme.base00; # mantle
        CHECK_BORDER = theme.base02; # surface1
        CHECK_BORDER_HOVER = theme.base0D; # blue
        CHECK_BG_HOVER = theme.base00; # base
        CHECK_BG_DISABLED = theme.base01; # crust

        BUTTON_PRIMARY_BG = theme.base0D; # blue
        BUTTON_PRIMARY_FG = theme.base01; # crust
        BUTTON_PRIMARY_BORDER = theme.base0D; # sapphire
        BUTTON_PRIMARY_BG_HOVER = theme.base0D; # sapphire
        BUTTON_PRIMARY_BG_PRESSED = theme.base07; # lavender
      };

      # base16 -> theme.css token substitution, done purely at eval time so the
      # build needs no extra tools.
      template = builtins.readFile ./theme.css.template;

      themeCss = builtins.replaceStrings (map (name: "%${name}%") (
        builtins.attrNames colors
      )) (builtins.attrValues colors) template;

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
