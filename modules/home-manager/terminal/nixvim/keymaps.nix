let
  mapKey = mode: key: action: {
    inherit mode key action;

    options.silent = true;
  };

  mapKeyWithOpts = mode: key: action: opts: (mapKey mode key action) // {options = opts;};
in {
  programs.nixvim.keymaps = [
    # Typos.
    (mapKeyWithOpts "n" "æ" ":" {nowait = true;})

    # Fix bad habits.
    (mapKey "" "<Up>" "<Nop>")
    (mapKey "" "<Down>" "<Nop>")
    (mapKey "" "<Left>" "<Nop>")
    (mapKey "" "<Right>" "<Nop>")

    # Save current buffer.
    (mapKey "" "<C-s>" ":w<CR>")

    # Move single lines.
    (mapKey "v" "J" ":m '>+1<CR>gv=gv")
    (mapKey "v" "K" ":m '<-2<CR>gv=gv")

    # Append line below to current line.
    (mapKey "n" "J" "mzJ`z")

    # Stay in the middle during half-page jumps.
    (mapKey "n" "<C-d>" "<C-d>zz")
    (mapKey "n" "<C-u>" "<C-u>zz")

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

    # Focus the file explorer.
    (mapKey "n" "<leader>e" "<cmd>Neotree action=focus reveal<CR>")

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
