{
  pkgs,
  lib,
  ...
}: {
  programs.alacritty = {
    enable = true;

    settings = {
      live_config_reload = true;

      mouse.hide_when_typing = true;
      cursor.unfocused_hollow = false;

      colors.draw_bold_text_with_bright_colors = true;
      bell.animation = "EaseOutExpo";

      font = let
        jetbrainsMono = style: {
          family = "JetBrainsMono Nerd Font";
          inherit style;
        };
      in {
        size = lib.mkForce 14;

        normal = lib.mkForce (jetbrainsMono "Regular");
        bold = jetbrainsMono "Bold";
        italic = jetbrainsMono "Italic";
        bold_italic = jetbrainsMono "Bold Italic";
      };

      env.TERM = "xterm-256color";

      shell = {
        program = "${pkgs.tmux}/bin/tmux";
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
