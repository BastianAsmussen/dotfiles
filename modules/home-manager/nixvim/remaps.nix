{
  programs.nixvim.keymaps = [
    # Correct `;` to `:`.
    {
      key = ";";
      action = ":";
    }
    # Save on `<C-s>`.
    {
      key = "<C-s>";
      action = ":w<CR>";
    }

    {
      mode = "v";
      key = "J";
      action = ":m '>+1<CR>gv=gv";
    }
    {
      mode = "v";
      key = "K";
      action = ":m '<-2<CR>gv=gv";
    }

    {
      mode = "n";
      key = "J";
      action = "mzJ`z";
    }

    # Stay in the middle during half-page jumps.
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
    }

    # Make search terms stay in the middle.
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
    }

    # Preserve paste buffer.
    {
      mode = "x";
      key = "<leader>p";
      action = "\"_dP";
    }

    # Yank to system clipboard.
    {
      mode = "n";
      key = "<leader>y";
      action = "\"+y";
    }
    {
      mode = "v";
      key = "<leader>y";
      action = "\"+y";
    }
    {
      mode = "n";
      key = "<leader>Y";
      action = "\"+Y";
    }

    # "Don't press Q, it's the worst place in the universe." - ThePrimeagen.
    {
      mode = "n";
      key = "Q";
      action = "<nop>";
    }

    # Quickly switch projects.
    {
      mode = "n";
      key = "<C-f>";
      action = "<cmd>silent !tmux neww tmux-sessionizer<CR>";
    }

    # Edit the current word.
    {
      mode = "n";
      key = "<leader>s";
      action = ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>";
    }
  ];
}
