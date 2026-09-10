{
  # Editor options, leader keys, and diagnostic sign glyphs.
  flake.nixvimModules.settings =
    { pkgs, ... }:
    {
      viAlias = true;
      vimAlias = true;
      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      performance.byteCompileLua = {
        enable = true;
        nvimRuntime = true;
        plugins = true;
      };

      opts = {
        number = true;
        relativenumber = true;
        showmode = false;
        undofile = true;

        # Neovim's default, spelled out: on the impermanent hosts this path is
        # bind-mounted from /persist, so whatever lands here is kept forever.
        # See the secret-file autocmd in autocmds.nix.
        undodir.__raw = ''vim.fn.stdpath("state") .. "/undo"'';

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

        termguicolors = pkgs.stdenv.hostPlatform.isLinux;
        updatetime = 50;
        timeoutlen = 300;
        colorcolumn = "80";
      };

      diagnostic.settings.virtual_text = false;
      extraConfigLuaPre = ''
          vim.fn.sign_define("diagnosticsignerror", { text = " ", texthl = "diagnosticerror", linehl = "", numhl = "" })
          vim.fn.sign_define("diagnosticsignwarn", { text = " ", texthl = "diagnosticwarn", linehl = "", numhl = "" })
          vim.fn.sign_define("diagnosticsignhint", { text = "󰝶 ", texthl = "diagnostichint", linehl = "", numhl = "" })
          vim.fn.sign_define("diagnosticsigninfo", { text = " ", texthl = "diagnosticinfo", linehl = "", numhl = "" })

          if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
          vim.g.clipboard = "osc52"
        end
      '';
    };
}
