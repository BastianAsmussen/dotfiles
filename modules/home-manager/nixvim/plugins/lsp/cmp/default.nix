{
  imports = [
    ./lspkind.nix
    ./luasnip.nix
  ];

  programs.nixvim = {
    opts.completeopt = ["menu" "menuone" "noselect"];

    plugins = {
      cmp = {
        enable = true;

        settings = {
          formatting.fields = ["kind" "abbr" "menu"];

          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };

          snippet.expand =
            /*
            lua
            */
            ''
              function(args)
                  require('luasnip').lsp_expand(args.body)
              end
            '';

          sources = [
            {name = "path";}
            {
              name = "nvim_lsp";
              keywordLength = 1;
            }
            {
              name = "luasnip";
              keywordLength = 2;
            }
            {
              name = "buffer";
              keywordLength = 3;
              # Words from other open buffers can also be suggested.
              option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            }
            {name = "crates";}
            {name = "calc";} # For math calculations.
          ];

          window = {
            documentation = {
              border = "rounded";
              max_height = "math.floor(40 * (40 / vim.o.lines))";
            };

            completion = {
              border = "rounded";
              col_offset = -3;
              side_padding = 0;
            };
          };
        };
      };

      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp-buffer.enable = true;
    };
  };
}
