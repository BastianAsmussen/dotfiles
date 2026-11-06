{ self, ... }:
{
  flake.homeModules.tuxedo =
    { pkgs, ... }:
    let
      inherit (self) theme;
    in
    {
      home.packages = [ pkgs.tuxedo ];

      # Restore the config symlink that Tuxedo replaces at runtime.
      xdg.configFile."tuxedo/config.toml" = {
        force = true;
        text = ''
          theme = Stylix
        '';
      };

      # Use Stylix base16 colors with tuxedo's bare #rrggbb parser format.
      xdg.configFile."tuxedo/themes/stylix.toml".text = ''
        name = "Stylix"
        bg = ${theme.base00}
        panel = ${theme.base00}
        border = ${theme.base02}
        fg = ${theme.base05}
        dim = ${theme.base03}
        accent = ${theme.base0E}
        cursor = ${theme.base06}
        selection = ${theme.base02}
        statusbar = ${theme.base01}
        status_fg = ${theme.base04}
        mode_fg = ${theme.base00}
        mode_bg = ${theme.base0D}
        pri_a = ${theme.base08}
        pri_b = ${theme.base09}
        pri_c = ${theme.base0A}
        pri_d = ${theme.base0B}
        pri_other = ${theme.base04}
        project = ${theme.base0B}
        context = ${theme.base0C}
        due = ${theme.base0A}
        overdue = ${theme.base08}
        today = ${theme.base0D}
        done = ${theme.base03}
        selected = ${theme.base01}
        matched = ${theme.base0A}
      '';
    };
}
