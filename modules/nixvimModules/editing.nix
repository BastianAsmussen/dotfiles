{
  # Text objects, motions, file management, and treesitter.
  flake.nixvimModules.editing =
    { pkgs, ... }:
    {
      plugins = {
        claude-code = {
          enable = true;
          settings.keymaps.toggle = {
            normal = "<leader>cc";
            terminal = "<leader>cc";
            variants = {
              continue = "<leader>cC";
              resume = "<leader>cR";
              verbose = "<leader>cV";
            };
          };
        };
        comment = {
          enable = true;
          settings.pre_hook =
            # lua
            ''
              require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
            '';
        };

        harpoon = {
          enable = true;
          enableTelescope = true;
        };

        markdown-preview = {
          enable = true;
          settings.theme = "dark";
        };

        oil = {
          enable = true;
          settings = {
            columns = [ "icon" ];
            view_options.show_hidden = true;
            keymaps = {
              "<C-r>" = "actions.refresh";
              "<leader>qq" = "actions.close";
              "<C-s>" = false;
            };
          };
        };

        sleuth.enable = true;
        tmux-navigator = {
          enable = true;
          keymaps = [
            {
              action = "up";
              key = "<C-k>";
            }
            {
              action = "down";
              key = "<C-j>";
            }
            {
              action = "left";
              key = "<C-h>";
            }
            {
              action = "right";
              key = "<C-l>";
            }
            {
              action = "previous";
              key = "<C-\\";
            }
          ];
        };

        treesitter = {
          enable = true;
          grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
          settings = {
            highlight = {
              enable = true;
              additional_vim_regex_highlighting = true;
            };

            indent.enable = true;
          };
        };

        ts-context-commentstring.enable = true;
        undotree.enable = true;
      };
    };
}
