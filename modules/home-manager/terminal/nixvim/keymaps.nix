let
  mapKey = mode: key: action: {
    inherit mode key action;

    options.silent = true;
  };

  mapKeyWithOpts = mode: key: action: options:
    (mapKey mode key action) // {inherit options;};
in {
  programs.nixvim.keymaps = [
    # Typos.
    (mapKeyWithOpts "n" "æ" ":" {nowait = true;})

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

    # Preserve paste buffer.
    (mapKey "x" "<leader>p" "\"_dP")

    # Yank to system clipboard.
    (mapKey "n" "<leader>y" "\"+y")
    (mapKey "v" "<leader>y" "\"+y")
    (mapKey "n" "<leader>Y" "\"+Y")

    # "Don't press Q, it's the worst place in the universe." - ThePrimeagen.
    (mapKey "n" "Q" "<Nop>")

    # Edit the current word.
    (mapKey "n" "<leader>s" ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

    # Manage open buffers.
    (mapKey "n" "<Tab>" "<cmd>BufferLineCycleNext<CR>")
    (mapKey "n" "<S-Tab>" "<cmd>BufferLineCyclePrev<CR>")
    (mapKey "n" "<leader>x" "<cmd>bdelete!<CR>")

    # Toggle comments.
    (mapKeyWithOpts "n" "<leader>/" "gcc" {remap = true;})
    (mapKeyWithOpts "v" "<leader>/" "gc" {remap = true;})

    # Focus the file explorer.
    (mapKey "n" "<leader>e" "<cmd>NvimTreeFocus<CR>")

    # LSP.
    (mapKey "n" "<leader>lc" "<cmd>Lspsaga code_action<CR>")
    (mapKey "n" "<leader>lff" "<cmd>Lspsaga finder<CR>")
    (mapKey "n" "<leader>lfi" "<cmd>Lspsaga finder imp<CR>")
    (mapKey "n" "<leader>lfI" "<cmd>Lspsaga incoming_calls<CR>")
    (mapKey "n" "<leader>lfo" "<cmd>Lspsaga outgoing_calls<CR>")
    (mapKey "n" "<leader>lr" "<cmd>Lspsaga rename<CR>")
    (mapKey "n" "<leader>lpd" "<cmd>Lspsaga peek_definition<CR>")
    (mapKey "n" "<leader>lpt" "<cmd>Lspsaga peek_type_definition<CR>")
    (mapKey "n" "<leader>lbl" "<cmd>BaconList<CR>")
    (mapKey "n" "<leader>lbs" "<cmd>BaconShow<CR>")
    (mapKey "n" "<leader>lo" "<cmd>Outline<CR>")
    (mapKey "n" "<leader>lO" "<cmd>Outline!<CR>")

    # Debugging.
    (mapKey "n" "<leader>dl" "<cmd>lua require 'dap'.step_into()<CR>")
    (mapKey "n" "<leader>dj" "<cmd>lua require 'dap'.step_over()<CR>")
    (mapKey "n" "<leader>dk" "<cmd>lua require 'dap'.step_out()<CR>")
    (mapKey "n" "<leader>dc>" "<cmd>lua require 'dap'.continue()<CR>")
    (mapKey "n" "<leader>db" "<cmd>lua require 'dap'.toggle_breakpoint()<CR>")
    (mapKey "n" "<leader>dd" "<cmd>lua require 'dap'.set_breakpoint(vim.fn.input('Breakpoint Condition: '))<CR>")
    (mapKey "n" "<leader>de" "<cmd>lua require 'dap'.terminate()<CR>")
    (mapKey "n" "<leader>dr" "<cmd>lua require 'dap'.run_last()<CR>")

    (mapKey "n" "<leader>dt" "<cmd>lua vim.cmd('RustLsp testables')<CR>")

    # Preview markdown files.
    (mapKey "n" "<leader>mp" "<cmd>MarkdownPreviewToggle<CR>")

    # Make it rain!
    (mapKey "n" "<leader>fml" "<cmd>CellularAutomaton make_it_rain<CR>")
  ];
}
