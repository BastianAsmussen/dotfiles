{
  pkgs,
  lib,
  config,
  ...
}: {
  viAlias = true;
  vimAlias = true;

  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  autoGroups.highlight-yank.clear = true;
  autoCmd = [
    {
      event = ["TextYankPost"];
      desc = "Highlight when yanking (copying) text";
      group = "highlight-yank";
      callback.__raw = ''
        function()
          vim.highlight.on_yank({ higroup = "IncSearch", timeout = 100 })
        end
      '';
    }
  ];

  performance = {
    byteCompileLua = {
      enable = true;

      nvimRuntime = true;
      plugins = true;
    };

    combinePlugins = {
      enable = true;

      standalonePlugins = ["nvim-treesitter"];
    };
  };

  extraConfigLuaPre = ''
    vim.fn.sign_define("diagnosticsignerror", { text = " ", texthl = "diagnosticerror", linehl = "", numhl = "" })
    vim.fn.sign_define("diagnosticsignwarn", { text = " ", texthl = "diagnosticwarn", linehl = "", numhl = "" })
    vim.fn.sign_define("diagnosticsignhint", { text = "󰝶 ", texthl = "diagnostichint", linehl = "", numhl = "" })
    vim.fn.sign_define("diagnosticsigninfo", { text = " ", texthl = "diagnosticinfo", linehl = "", numhl = "" })
  '';

  # Use the OSC 52 escape sequence for clipboard operations over SSH.
  # Neovim 0.10+ supports this natively. When connected via SSH, the terminal
  # emulator interprets OSC 52 and copies text to the client's system
  # clipboard — no X11/Wayland forwarding needed.
  extraConfigLuaPost = ''
    if os.getenv('SSH_TTY') then
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
          ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }
    end
  '';

  opts = {
    number = true;
    relativenumber = true;
    showmode = false;

    undofile = true;
    backup = false;
    swapfile = false;

    hlsearch = true;
    ignorecase = true;
    smartcase = true;
    inccommand = "split";

    tabstop = 4;
    softtabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    smartindent = true;
    wrap = false;
    breakindent = true;
    scrolloff = 8;

    cursorline = true;

    signcolumn = "yes";
    list = true;
    listchars = {
      tab = "» ";
      trail = "·";
      nbsp = "␣";
    };

    termguicolors = pkgs.stdenv.isLinux;

    updatetime = 50;
    timeoutlen = 300;

    colorcolumn = "80";
  };

  diagnostic.settings.virtual_text = false;

  colorschemes.catppuccin = {
    enable = true;

    settings = {
      flavour = "mocha";
      styles = {
        booleans = [
          "bold"
          "italic"
        ];

        conditionals = [
          "bold"
        ];
      };
    };
  };

  keymaps = let
    mapKey = mode: key: action: {
      inherit mode key action;

      options.silent = true;
    };

    mapKeyWithOpts = mode: key: action: options:
      (mapKey mode key action) // {inherit options;};
  in [
    # Save the current buffer.
    (mapKey "" "<C-s>" "<cmd>w<CR>")

    # Move single lines.
    (mapKey "v" "K" ":m '<-2<CR>gv=gv")
    (mapKey "v" "J" ":m '>+1<CR>gv=gv")

    # Append line below to the current line.
    (mapKey "n" "J" "mzJ`z")

    # Stay in the middle during half-page jumps.
    (mapKey "n" "<C-u>" "<C-u>zz")
    (mapKey "n" "<C-d>" "<C-d>zz")

    # Make search terms stay in the middle.
    (mapKey "n" "n" "nzzzv")
    (mapKey "n" "N" "Nzzzv")

    # Clear highlights on search.
    (mapKey "n" "<Esc>" "<cmd>nohlsearch<CR>")

    # Preserve paste buffer.
    (mapKey "x" "<leader>p" "\"_dP")

    # Yank to system clipboard.
    (mapKey "n" "<leader>y" "\"+y")
    (mapKey "v" "<leader>y" "\"+y")
    (mapKey "n" "<leader>Y" "\"+Y")

    # Toggle the undo tree.
    (mapKeyWithOpts "n" "<leader>u" "<cmd>UndotreeToggle<CR>" {
      desc = "Undotree: Toggle the undo tree.";
    })

    # "Don't press Q, it's the worst place in the universe." - ThePrimeagen.
    (mapKey "n" "Q" "<Nop>")

    # Edit the current word.
    (mapKey "n" "<leader>s" ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

    # Manage open buffers.
    (mapKeyWithOpts "n" "<leader>db" "<cmd>bdelete!<CR>" {
      desc = "Buffer: [D]elete [B]uffer";
    })

    # Open parent directory in current window.
    (mapKeyWithOpts "n" "<leader>e" "<cmd>Oil<CR>" {
      desc = "Oil: Open the parent directory.";
    })

    # Toggle comments.
    (mapKeyWithOpts "n" "<leader>tc" "gcc" {
      remap = true;
      desc = "[T]oggle [C]omment";
    })
    (mapKeyWithOpts "v" "<leader>tc" "gc" {
      remap = true;
      desc = "[T]oggle [C]omment";
    })

    # Debugging.
    (mapKeyWithOpts "n" "<F1>" {
      __raw = ''
        function()
          require('dap').step_into()
        end
      '';
    } {desc = "Debug: Step Into";})
    (mapKeyWithOpts "n" "<F2>" {
      __raw = ''
        function()
          require('dap').step_over()
        end
      '';
    } {desc = "Debug: Step Over";})
    (mapKeyWithOpts "n" "<F3>" {
      __raw = ''
        function()
          require('dap').step_out()
        end
      '';
    } {desc = "Debug: Step Out";})
    (mapKeyWithOpts "n" "<F5>" {
      __raw = ''
        function()
          require('dap').continue()
        end
      '';
    } {desc = "Debug: Start/Continue";})
    (mapKeyWithOpts "n" "<leader>b" {
      __raw = ''
        function()
          require('dap').toggle_breakpoint()
        end
      '';
    } {desc = "Debug: Toggle Breakpoint";})
    (mapKeyWithOpts "n" "<leader>B" {
      __raw = ''
        function()
          require('dap').set_breakpoint(vim.fn.input 'Breakpoint Condition: ')
        end
      '';
    } {desc = "Debug: Set Breakpoint";})
    (mapKeyWithOpts "n" "<F7>" {
      __raw = ''
        function()
          require('dapui').toggle()
        end
      '';
    } {desc = "Debug: See last session result.";})

    # Telescope keybinds.
    (mapKeyWithOpts "n" "<leader>/" {
      __raw = ''
        function()
          require('telescope.builtin').current_buffer_fuzzy_find(
            require('telescope.themes').get_dropdown {
              winblend = 10,
              previewer = false
            }
          )
        end
      '';
    } {desc = "[/] Fuzzily search in current buffer";})
    (mapKeyWithOpts "n" "<leader>s/" {
      __raw = ''
        function()
          require('telescope.builtin').live_grep {
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files'
          }
        end
      '';
    } {desc = "[S]earch [/] in Open Files";})

    # Harpoon binds.
    (mapKey "n" "<leader>a" {
      __raw = ''
        function()
          require('harpoon'):list():add()
        end
      '';
    })
    (mapKey "n" "<C-e>" {
      __raw = ''
        function()
          local harpoon = require('harpoon')

          harpoon.ui:toggle_quick_menu(harpoon:list())
        end
      '';
    })

    (mapKey "n" "<C-j>" {
      __raw = ''
        function()
          require('harpoon'):list():select(1)
        end
      '';
    })
    (mapKey "n" "<C-k>" {
      __raw = ''
        function()
          require('harpoon'):list():select(2)
        end
      '';
    })
    (mapKey "n" "<C-l>" {
      __raw = ''
        function()
          require('harpoon'):list():select(3)
        end
      '';
    })

    (mapKey "n" "<C-m>" {
      __raw = ''
        function()
          require('harpoon'):list():select(4)
        end
      '';
    })

    # Toggle LSP lines.
    (mapKeyWithOpts "n" "<leader>tl" {
      __raw = ''
        function()
          require('lsp_lines').toggle {}
        end
      '';
    } {desc = "LSP: [T]oggle [L]ines";})

    # Preview markdown files.
    (mapKeyWithOpts "n" "<leader>mp" "<cmd>MarkdownPreviewToggle<CR>" {
      desc = "[M]arkdown [P]review";
    })

    # Make it rain!
    (mapKeyWithOpts "n" "<leader>fml" "<cmd>CellularAutomaton make_it_rain<CR>" {
      desc = "[F]uck [M]y [L]ife";
    })
  ];

  plugins = {
    cmp = {
      enable = true;

      settings = {
        mapping = {
          "<C-d>" = "cmp.mapping.scroll_docs(-4)";
          "<C-e>" = "cmp.mapping.close()";
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-y>" = "cmp.mapping.confirm { select = true }";
          "<C-Space>" = "cmp.mapping.complete {}";
          "<C-l>" =
            # lua
            ''
              cmp.mapping(function()
                if luasnip.expand_or_locally_jumpable() then
                  luasnip.expand_or_jump()
                end
              end, { 'i', 's' })
            '';
          "<C-h>" =
            # lua
            ''
              cmp.mapping(function()
                if luasnip.locally_jumpable(-1) then
                  luasnip.jump(-1)
                end
              end, { 'i', 's' })
            '';
        };

        formatting.fields = [
          "kind"
          "abbr"
          "menu"
        ];

        completion.completeopt = "menu,menuone,noinsert";
        snippet.expand =
          # lua
          ''
            function(args)
                require('luasnip').lsp_expand(args.body)
            end
          '';

        sources = [
          {name = "nvim_lsp";}
          {name = "path";}
          {
            name = "buffer";
            # Words from other open buffers can also be suggested.
            option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
          }
        ];

        window = {
          completion.border = "rounded";
          documentation.border = "rounded";
        };
      };
    };

    crates.enable = true;

    colorizer = {
      enable = true;

      settings.user_default_options.names = false;
    };

    comment = {
      enable = true;

      settings.pre_hook =
        # lua
        ''
          require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook()
        '';
    };

    dap = {
      enable = true;

      signs = {
        dapBreakpoint = {
          text = "";
          texthl = "DapBreakpoint";
        };

        dapBreakpointCondition = {
          text = "";
          texthl = "DapBreakpointCondition";
        };

        dapLogPoint = {
          text = "";
          texthl = "DapLogPoint";
        };
      };

      adapters.executables.lldb.command = "${pkgs.lldb}/bin/lldb-dap";
    };

    dap-ui = {
      enable = true;

      settings = {
        floating.mappings.close = ["<ESC>" "q"];
        icons = {
          expanded = "▾";
          collapsed = "▸";
          current_frame = "*";
        };

        controls = {
          icons = {
            pause = "⏸";
            play = "▶";
            step_into = "⏎";
            step_over = "⏭";
            step_out = "⏮";
            step_back = "b";
            run_last = "▶▶";
            terminate = "⏹";
            disconnect = "⏏";
          };
        };
      };
    };

    dap-virtual-text.enable = true;
    cmp-dap.enable = true;

    fidget.enable = true;

    gitsigns = {
      enable = true;

      settings = {
        current_line_blame = true;
        trouble = config.plugins.trouble.enable;
      };
    };

    harpoon = {
      enable = true;
      enableTelescope = true;
    };

    indent-blankline.enable = true;

    lsp = {
      enable = true;

      inlayHints = true;
      servers = {
        clangd.enable = true;
        cssls.enable = true;
        dockerls = {
          enable = true;

          settings.docker.languageserver.formatter.ignoreMultilineInstructions = true;
        };

        eslint.enable = true;
        gopls.enable = true;
        hls = {
          enable = true;

          installGhc = true;
        };

        html.enable = true;
        java_language_server.enable = true;
        lua_ls = {
          enable = true;

          settings.telemetry.enable = false;
        };

        nixd = {
          enable = true;

          settings.formatting.command = lib.mkDefault ["${lib.getExe pkgs.alejandra}"];
        };

        omnisharp.enable = true;
        pylsp.enable = true;
        sqls.enable = true;
        svelte.enable = true;
        tailwindcss.enable = true;
        taplo.enable = true;
        ts_ls.enable = true;
        typos_lsp = {
          enable = true;

          extraOptions.init_options.diagnosticSeverity = "Hint";
        };
      };

      keymaps = {
        diagnostic."<leader>q" = {
          action = "setloclist";
          desc = "Open diagnostic [Q]uickfix list";
        };

        extra = [
          {
            mode = "n";
            key = "gd";
            action.__raw = "require('telescope.builtin').lsp_definitions";
            options.desc = "LSP: [G]oto [D]efinition";
          }
          {
            mode = "n";
            key = "gr";
            action.__raw = "require('telescope.builtin').lsp_references";
            options.desc = "LSP: [G]oto [R]eferences";
          }
          {
            mode = "n";
            key = "gI";
            action.__raw = "require('telescope.builtin').lsp_implementations";
            options.desc = "LSP: [G]oto [I]mplementation";
          }
          {
            mode = "n";
            key = "<leader>D";
            action.__raw = "require('telescope.builtin').lsp_type_definitions";
            options.desc = "LSP: Type [D]efinition";
          }
          {
            mode = "n";
            key = "<leader>ds";
            action.__raw = "require('telescope.builtin').lsp_document_symbols";
            options = {
              desc = "LSP: [D]ocument [S]ymbols";
            };
          }
          {
            mode = "n";
            key = "<leader>ws";
            action.__raw = "require('telescope.builtin').lsp_dynamic_workspace_symbols";
            options = {
              desc = "LSP: [W]orkspace [S]ymbols";
            };
          }
        ];

        lspBuf = {
          "<leader>rn" = {
            action = "rename";
            desc = "LSP: [R]e[n]ame";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "LSP: [C]ode [A]ction";
          };
          "gD" = {
            action = "declaration";
            desc = "LSP: [G]oto [D]eclaration";
          };
        };
      };

      onAttach =
        # lua
        ''
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- The following two autocommands are used to highlight references
          -- of the word under the cursor when your cursor rests there for a
          -- little while. When you move your cursor, the highlights will be
          -- cleared (the second autocommand).
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them.
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        '';
    };

    lsp-format.enable = true;

    lspkind = {
      enable = true;

      settings = {
        mode = "symbol_text";
        maxwidth = 50;
        ellipsis_char = "...";
      };
    };

    lsp-lines.enable = true;

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

    luasnip = {
      enable = true;

      settings = {
        enable_autosnippets = true;
        store_selection_keys = "<Tab>";
      };

      fromVscode = [
        {
          lazyLoad = true;
          paths = "${pkgs.vimPlugins.friendly-snippets}";
        }
      ];
    };

    markdown-preview = {
      enable = true;

      settings.theme = "dark";
    };

    nix.enable = true;

    none-ls = {
      enable = true;

      sources = {
        code_actions = {
          gitsigns.enable = true;
          statix.enable = true;
        };

        diagnostics = {
          checkstyle.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          pylint.enable = true;
        };

        formatting = {
          alejandra.enable = true;
          stylua.enable = true;
          shfmt.enable = true;
          google_java_format.enable = false;
          markdownlint.enable = true;
          prettier = {
            enable = true;

            disableTsServerFormatter = true;
          };
        };
      };
    };

    nvim-autopairs.enable = true;

    oil = {
      enable = true;

      settings = {
        columns = ["icon"];
        view_options.show_hidden = true;
        keymaps = {
          "<C-r>" = "actions.refresh";
          "<leader>qq" = "actions.close";
          "<C-s>" = false;
        };
      };
    };

    rustaceanvim = {
      enable = true;

      settings = {
        server = {
          load_vscode_settings = true;
          default_settings.rust-analyzer = {
            cargo.features = "all";
            check = {
              command = "clippy";
              extraArgs = lib.mkDefault ["--"];
              allTargets = true;
            };

            assist = {
              emitMustUse = true;
              expressionFillDefault = "default";
            };

            completion = {
              termSearch.enable = true;
              fullFunctionSignatures.enable = true;
              privateEditable.enable = true;
            };

            diagnostics.styleLints.enable = true;
            imports = {
              granularity.enforce = true;
              preferPrelude = true;
            };

            inlayHints = {
              closureReturnTypeHints.enable = "with_block";
              closureStyle = "rust_analyzer";
            };

            lens.references = {
              adt.enable = true;
              enumVariant.enable = true;
              method.enable = true;
            };

            interpret.tests = true;
            workspace.symbol.search.scope = "workspace_and_dependencies";
            typing.autoClosingAngleBrackets.enable = true;
          };

          dap.adapter = {
            command = "${pkgs.lldb}/bin/lldb-dap";
            type = "executable";
          };
        };
      };
    };

    sleuth.enable = true;

    telescope = {
      enable = true;

      keymaps = {
        "<leader>sh" = {
          mode = "n";
          action = "help_tags";
          options = {
            desc = "[S]earch [H]elp";
          };
        };
        "<leader>sk" = {
          mode = "n";
          action = "keymaps";
          options = {
            desc = "[S]earch [K]eymaps";
          };
        };
        "<leader>sf" = {
          mode = "n";
          action = "find_files";
          options = {
            desc = "[S]earch [F]iles";
          };
        };
        "<leader>ss" = {
          mode = "n";
          action = "builtin";
          options = {
            desc = "[S]earch [S]elect Telescope";
          };
        };
        "<leader>sw" = {
          mode = "n";
          action = "grep_string";
          options = {
            desc = "[S]earch current [W]ord";
          };
        };
        "<leader>sg" = {
          mode = "n";
          action = "live_grep";
          options = {
            desc = "[S]earch by [G]rep";
          };
        };
        "<leader>sd" = {
          mode = "n";
          action = "diagnostics";
          options = {
            desc = "[S]earch [D]iagnostics";
          };
        };
        "<leader>sr" = {
          mode = "n";
          action = "resume";
          options = {
            desc = "[S]earch [R]esume";
          };
        };
        "<leader>s" = {
          mode = "n";
          action = "oldfiles";
          options = {
            desc = "[S]earch Recent Files ('.' for repeat)";
          };
        };
        "<leader><leader>" = {
          mode = "n";
          action = "buffers";
          options = {
            desc = "[ ] Find existing buffers";
          };
        };
      };

      settings.defaults = {
        file_ignore_patterns = [
          "^.git/"
          "^.mypy_cache/"
          "^__pycache__/"
          "^output/"
          "^data/"
          "%.ipynb"
          "^target/"
        ];

        set_env.COLORTERM = "truecolor";
      };

      extensions = {
        fzf-native.enable = true;
        ui-select.enable = true;
      };
    };

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

    treesitter-context = {
      enable = true;

      settings.max_lines = 3;
    };

    trouble.enable = true;
    ts-context-commentstring.enable = true;
    typescript-tools.enable = true;
    undotree.enable = true;
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

  extraPlugins = with pkgs.vimPlugins; [
    cellular-automaton-nvim
    vim-be-good
  ];

  extraConfigLua = ''
    local dap = require('dap')

    dap.listeners.after.event_initialized['dapui_config'] = require('dapui').open
    dap.listeners.before.event_terminated['dapui_config'] = require('dapui').close
    dap.listeners.before.event_exited['dapui_config'] = require('dapui').close

    -- Default LLDB debug configuration for C and C++. Without this,
    -- dap.continue() has no configurations for these filetypes and falls back
    -- to prompting the user to pick an adapter manually.
    -- Rust is handled by rustaceanvim which registers its own dap
    -- configurations, so it does not need an entry here.
    local lldb_config = {
      {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = vim.fn.getcwd(),
        stopOnEntry = false,
      },
    }

    dap.configurations.c = lldb_config
    dap.configurations.cpp = lldb_config

    require('cmp').event:on('confirm_done', require('nvim-autopairs.completion.cmp').on_confirm_done())
  '';
}
