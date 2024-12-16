{
  config,
  osConfig,
  lib,
  pkgs,
  userInfo,
  ...
}: {
  programs.nixvim.plugins = {
    none-ls = import ./none-ls.nix;

    lsp = {
      enable = true;

      inlayHints = true;
      servers = {
        clangd.enable = true; # C/C++
        cssls.enable = true; # CSS
        dockerls = import ./dockerls.nix; # Docker
        gopls.enable = true; # Golang
        hls = import ./hls.nix; # Haskell
        html.enable = true; # HTML
        java_language_server.enable = true; # Java
        lua_ls = import ./lua_ls.nix;
        nixd = import ./nixd.nix {
          inherit osConfig config lib pkgs userInfo;
        }; # Nix

        omnisharp = import ./omnisharp.nix; # C#
        pylsp.enable = true; # Python
        sqls.enable = true; # SQL
        svelte.enable = true; # Svelte
        ts_ls.enable = true; # TS/JS
        typos_lsp = import ./typos_lsp.nix;
      };

      keymaps = import ./keymaps.nix;
      onAttach =
        # lua
        ''
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
          end

          -- The following two autocommands are used to highlight references
          -- of the word under the cursor when your cursor rests there for a
          -- little while. When you move your cursor, the highlights will be
          -- cleared (the second autocommand).
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = bufnr,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them.
          -- This may be unwanted, since they displace some of your code
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        '';
    };
  };
}
