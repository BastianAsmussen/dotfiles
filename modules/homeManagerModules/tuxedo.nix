{ self, ... }:
{
  flake.homeModules.tuxedo =
    { pkgs, ... }:
    let
      inherit (self) theme;
    in
    {
      home.packages = [ pkgs.tuxedo ];

      # Select the theme at startup; a file in themes/ is only selectable,
      # not active. tuxedo rewrites this file at runtime (pref toggles,
      # share_token), replacing the symlink with a regular file; force
      # restores the link on rebuild instead of aborting with a .backup
      # collision.
      xdg.configFile."tuxedo/config.toml" = {
        force = true;
        text = ''
          theme = Stylix
        '';
      };

      # Colours are derived from the stylix base16 palette (self.theme)
      # rather than hardcoded, so the theme tracks the active scheme like
      # every other module. Values are bare #rrggbb per tuxedo's parser
      # (not real TOML).
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
