{inputs, self, ...}: {
  flake = {
    flakeModules.nvfConfig = {
      vim = {
        enableLuaLoader = true;
        
        viAlias = true;
        vimAlias = true;
        globals.maplocalleader = " ";

        theme = {
          enable = true;

          name = "catppuccin";
          style = "mocha";
        };

        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        lsp.enable = true;
        languages = {
          enableTreesitter = true;

          nix.enable = true;
          ts.enable = true;
          rust.enable = true;
        };

        keymaps = let
          mapKey = mode: key: action: {
            inherit mode key action;

            silent = true;
          };
        in [
          # Save the current buffer.
          (mapKey "n" "<C-s>" "<cmd>w<CR>")

          # Move single lines.
          (mapKey "v" "J" ":m '>+1<CR>gv=gv")
          (mapKey "v" "K" ":m '<-2<CR>gv=gv")

          # Append line below to the current line.
          (mapKey "n" "J" "mzJ`z")

          # Yank to system clipboard.
          (mapKey ["n" "v"] "<leader>y" "\"+y")
          (mapKey "n" "<leader>Y" "\"+Y")

          # Toggle the undo tree.
          (mapKey "n" "<leader>u" "<cmd>UndotreeToggle<CR>")

          # "Don't press Q, it's the worst place in the universe." - ThePrimeagen.
          (mapKey "n" "Q" "<Nop>")

          # Edit the current word.
          (mapKey "n" "<leader>s" ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")
        ];
      };
    };

    nixosModules.neovim = {pkgs, ...}: {
      imports = [
        inputs.nvf.nixosModules.default
      ];

      programs.nvf = {
        enable = true;

        settings = self.flakeModules.nvfConfig;
      };
    };
  };
}