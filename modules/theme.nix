let
  theme = {
    base00 = "#1e1e2e"; # base (bg)
    base01 = "#313244"; # surface0 (dark)
    base02 = "#45475a"; # surface1
    base03 = "#6c7086"; # overlay0
    base04 = "#a6adc8"; # subtext0
    base05 = "#cdd6f4"; # text
    base06 = "#f5e0dc"; # rosewater
    base07 = "#b4befe"; # lavender
    base08 = "#f38ba8"; # red
    base09 = "#fab387"; # peach
    base0A = "#f9e2af"; # yellow
    base0B = "#a6e3a1"; # green
    base0C = "#94e2d5"; # teal
    base0D = "#89b4fa"; # blue
    base0E = "#cba6f7"; # mauve
    base0F = "#f2cdcd"; # flamingo
  };

  stripHash = str:
    if builtins.substring 0 1 str == "#"
    then builtins.substring 1 (builtins.stringLength str - 1) str
    else str;

  themeNoHash = builtins.mapAttrs (_: stripHash) theme;
in {
  flake = {
    inherit theme themeNoHash;
  };
}
