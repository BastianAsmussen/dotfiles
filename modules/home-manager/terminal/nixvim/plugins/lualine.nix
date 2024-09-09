{
  programs.nixvim.plugins.lualine = {
    enable = true;

    settings = {
      options = {
        globalstatus = true;
        component_separators = {
          left = "|";
          right = "|";
        };

        section_separators = {
          left = "";
          right = "";
        };

        disabled_filetypes.statusline = [
          "dashboard"
        ];
      };

      sections = {
        lualine_a = [
          {
            __unkeyed-1 = "mode";
            icon = "";
          }
        ];

        lualine_b = [
          {
            __unkeyed-1 = "branch";
            icon = "";
          }
          {
            __unkeyed-1 = "diff";
            symbols = {
              added = " ";
              modified = " ";
              removed = " ";
            };
          }
        ];

        lualine_c = [
          {
            __unkeyed-1 = "diagnostics";
            sources = [
              "nvim_lsp"
            ];

            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰝶 ";
            };
          }
        ];

        lualine_x = [
          {
            __unkeyed-1 = "filetype";
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed-1 = "filename";
            path = 4;
          }
        ];

        lualine_y = [
          "progress"
        ];

        lualine_z = [
          "location"
        ];
      };
    };
  };
}
