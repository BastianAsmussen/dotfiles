{
  # Completion sources, snippets, and autopairs.
  flake.nixvimModules.completion =
    { lib, pkgs, ... }:
    {
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
              { name = "nvim_lsp"; }
              { name = "path"; }
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

        nvim-autopairs.enable = true;
        lspkind = {
          enable = true;
          settings = {
            mode = "symbol_text";
            maxwidth = 50;
            ellipsis_char = "...";
          };
        };
      };
      extraConfigLua = lib.mkAfter ''
        require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
      '';
    };
}
