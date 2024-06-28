{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.alacritty = {
    enable = true;

    settings = {
      live_config_reload = true;

      bell = {
        animation = "EaseOutExpo";
        duration = 0;
      };

      colors.draw_bold_text_with_bright_colors = true;

      cursor = {
        blink_interval = 500;
        blink_timeout = 5;
        unfocused_hollow = false;

        style = {
          blinking = "Off";
          shape = "Block";
        };
      };

      env.TERM = "xterm-256color";

      font = {
        size = lib.mkForce 14;

        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };

        italic.family = "JetBrainsMono Nerd Font";

        normal = {
          family = lib.mkForce "JetBrainsMono Nerd Font";
          style = lib.mkForce "Regular";
        };

        offset = {
          x = 0;
          y = 0;
        };

        glyph_offset = {
          x = 0;
          y = 0;
        };
      };

      mouse = {
        hide_when_typing = true;

        bindings = [
          {
            action = "PasteSelection";
            mouse = "Middle";
          }
        ];
      };

      selection.semantic_escape_chars = ",│`|:\"' ()[]{}<>";

      # TODO: Open tmux on launch.

      window = {
        decorations = "full";
        dynamic_title = true;
        startup_mode = "Maximized";

        dimensions = {
          columns = 160;
          lines = 80;
        };

        padding = {
          x = 4;
          y = 4;
        };
      };
    };
  };
}
