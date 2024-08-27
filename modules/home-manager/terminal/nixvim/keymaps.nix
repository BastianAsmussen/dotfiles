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

    # Make it rain!
    (mapKey "n" "<leader>fml" "<cmd>CellularAutomaton make_it_rain<CR>")
  ];
}
