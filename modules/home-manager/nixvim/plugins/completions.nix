{
  programs.nixvim = {
    opts.completeopt = ["menu" "menuone" "noselect"];

    plugins = {
      cmp = {
        enable = true;

        settings = {
          formatting.fields = ["menu" "abbr" "kind"];

          mapping = {
            "<C-d>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
          };

          snippet.expand = "luasnip";

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
            completion = {
              border = "rounded";
              side_padding = 0;
            };

            documentation = {
              border = "rounded";
              side_padding = 0;
            };
          };
        };
      };

      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;
      cmp-buffer.enable = true;

      luasnip.enable = true;

      lspkind = {
        enable = true;

        cmp.enable = true;
        extraOptions = {
          maxwidth = 50;
          ellipsis_char = "...";
        };
      };
    };
  };
}
