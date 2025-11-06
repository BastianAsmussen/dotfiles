{
  self,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages = {
      terminal = pkgs.alacritty;
      alacritty = (inputs.wrappers.wrapperModules.alacritty.apply {
        inherit pkgs;

        settings = {
          general.live_config_reload = true;
          env.TERM = "xterm-256color";
          
          mouse.hide_when_typing = true;
          cursor.unfocused_hollow = false;

          bell.animation = "EaseOutExpo";
          colors = with self.theme; {
            draw_bold_text_with_bright_colors = true;
            primary = {
              foreground = base05;
              background = base00;
              bright_foreground = base07;
            };

            selection = {
              text = base05;
              background = base02;
            };

            cursor = {
              text = base00;
              cursor = base05;
            };

            normal = {
              inherit red green yellow blue cyan;
              
              magenta = purple;
              black = base00;
              white = base05;
            };

            bright = {
              inherit red green yellow blue cyan;

              magenta = purple;
              black = base03;
              white = base07;
            };
          };
          
          scrolling.history = 16 * 1024;
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
      }).wrapper;
    };
  };
}