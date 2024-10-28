{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkForce;
in {
  programs.alacritty = {
    enable = true;

    settings = {
      general.live_config_reload = true;
      mouse.hide_when_typing = true;
      cursor.unfocused_hollow = false;
      scrolling.history = config.programs.zsh.history.size;

      colors.draw_bold_text_with_bright_colors = true;
      bell.animation = "EaseOutExpo";

      font = let
        jetbrainsMono = style: {
          inherit style;

          family = "JetBrainsMono Nerd Font";
        };
      in {
        size = mkForce 14;

        normal = mkForce (jetbrainsMono "Regular");
        bold = jetbrainsMono "Bold";
        italic = jetbrainsMono "Italic";
        bold_italic = jetbrainsMono "Bold Italic";
      };

      env.TERM = "xterm-256color";

      terminal.shell = {
        program = "${lib.getExe pkgs.tmux}";
        args = ["attach"];
      };

      window = {
        startup_mode = "Maximized";

        dimensions = {
          columns = 160;
          lines = 80;
        };

        padding = {
          x = 4;
          y = 8;
        };
      };
    };
  };
}
