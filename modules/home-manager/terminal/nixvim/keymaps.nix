let
  mapKey = mode: key: action: {
    inherit mode key action;

    options.silent = true;
  };

  mapKeyWithOpts = mode: key: action: options:
    (mapKey mode key action) // {inherit options;};
in {
  programs.nixvim.keymaps = [
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

    # Preview markdown files.
    (mapKeyWithOpts "n" "<leader>mp" "<cmd>MarkdownPreviewToggle<CR>" {
      desc = "[M]arkdown [P]review";
    })

    # Make it rain!
    (mapKeyWithOpts "n" "<leader>fml" "<cmd>CellularAutomaton make_it_rain<CR>" {
      desc = "[F]uck [M]y [L]ife";
    })
  ];
}
