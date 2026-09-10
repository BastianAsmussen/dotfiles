{
  # Statusline, gutter, indent guides, and other chrome.
  flake.nixvimModules.ui =
    { config, ... }:
    {
      plugins = {
        colorizer = {
          enable = true;
          settings.user_default_options.names = false;
        };

        fidget.enable = true;
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = true;
            trouble = config.plugins.trouble.enable;
          };
        };

        indent-blankline.enable = true;
        lualine = {
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
                    added = " ";
                    modified = " ";
                    removed = " ";
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
                    hint = "󰝶 ";
                    info = " ";
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

        treesitter-context = {
          enable = true;
          settings.max_lines = 3;
        };

        trouble.enable = true;
        web-devicons.enable = true;
        which-key = {
          enable = true;
          settings = {
            spec = [
              {
                __unkeyed-1 = "<leader>c";
                group = "[C]ode";
              }
              {
                __unkeyed-1 = "<leader>d";
                group = "[D]ocument";
              }
              {
                __unkeyed-1 = "<leader>r";
                group = "[R]ename";
              }
              {
                __unkeyed-1 = "<leader>s";
                group = "[S]earch";
              }
              {
                __unkeyed-1 = "<leader>w";
                group = "[W]orkspace";
              }
              {
                __unkeyed-1 = "<leader>t";
                group = "[T]oggle";
              }
              {
                __unkeyed-1 = "<leader>h";
                group = "Git [H]unk";
                mode = [
                  "n"
                  "v"
                ];
              }
            ];
          };
        };
      };
    };
}
