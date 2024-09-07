{
  programs.nixvim.plugins.lualine = {
    enable = true;

    globalstatus = true;
    componentSeparators = {
      left = "|";
      right = "|";
    };

    sectionSeparators = {
      left = "";
      right = "";
    };

    disabledFiletypes.statusline = ["dashboard"];
    sections = {
      lualine_a = [
        {
          name = "mode";
          icon = "";
        }
      ];

      lualine_b = [
        {
          name = "branch";
          icon = "";
        }
        {
          name = "diff";
          extraConfig.symbols = {
            added = " ";
            modified = " ";
            removed = " ";
          };
        }
      ];

      lualine_c = [
        {
          name = "diagnostics";
          extraConfig = {
            sources = ["nvim_lsp"];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰝶 ";
            };
          };
        }
      ];

      lualine_x = [
        {
          name = "filetype";
          extraConfig = {
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          };
        }
        {
          name = "filename";
          extraConfig.path = 4;
        }
      ];

      lualine_y = ["progress"];
      lualine_z = ["location"];
    };
  };
}
