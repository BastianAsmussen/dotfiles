{
  # Language servers, formatting, and per-language tooling.
  flake.nixvimModules.lsp =
    { pkgs, lib, ... }:
    {
      plugins = {
        lsp = {
          enable = true;
          inlayHints = true;
          servers = {
            clangd.enable = true;
            cssls.enable = true;
            dockerls = {
              enable = true;
              settings.docker.languageserver.formatter.ignoreMultilineInstructions = true;
            };

            eslint.enable = true;
            gopls.enable = true;
            hls = {
              enable = true;
              installGhc = true;
            };

            html.enable = true;
            java_language_server.enable = true;
            lua_ls = {
              enable = true;
              settings.telemetry.enable = false;
            };

            nixd = {
              enable = true;
              settings.formatting.command = lib.mkDefault [ "${lib.getExe pkgs.nixfmt}" ];
            };

            omnisharp.enable = true;
            pylsp.enable = true;
            sqls.enable = true;
            svelte.enable = true;
            tailwindcss.enable = true;
            taplo.enable = true;
            ts_ls.enable = true;
            typos_lsp = {
              enable = true;
              extraOptions.init_options.diagnosticSeverity = "Hint";
            };
          };

          keymaps = {
            diagnostic."<leader>q" = {
              action = "setloclist";
              desc = "Open diagnostic [Q]uickfix list";
            };

            extra = [
              {
                mode = "n";
                key = "gd";
                action.__raw = "require('telescope.builtin').lsp_definitions";
                options.desc = "LSP: [G]oto [D]efinition";
              }
              {
                mode = "n";
                key = "gr";
                action.__raw = "require('telescope.builtin').lsp_references";
                options.desc = "LSP: [G]oto [R]eferences";
              }
              {
                mode = "n";
                key = "gI";
                action.__raw = "require('telescope.builtin').lsp_implementations";
                options.desc = "LSP: [G]oto [I]mplementation";
              }
              {
                mode = "n";
                key = "<leader>D";
                action.__raw = "require('telescope.builtin').lsp_type_definitions";
                options.desc = "LSP: Type [D]efinition";
              }
              {
                mode = "n";
                key = "<leader>ds";
                action.__raw = "require('telescope.builtin').lsp_document_symbols";
                options = {
                  desc = "LSP: [D]ocument [S]ymbols";
                };
              }
              {
                mode = "n";
                key = "<leader>ws";
                action.__raw = "require('telescope.builtin').lsp_dynamic_workspace_symbols";
                options = {
                  desc = "LSP: [W]orkspace [S]ymbols";
                };
              }
            ];

            lspBuf = {
              "<leader>rn" = {
                action = "rename";
                desc = "LSP: [R]e[n]ame";
              };
              "<leader>ca" = {
                action = "code_action";
                desc = "LSP: [C]ode [A]ction";
              };
              "gD" = {
                action = "declaration";
                desc = "LSP: [G]oto [D]eclaration";
              };
            };
          };

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
              if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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
              if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                map('<leader>th', function()
                  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                end, '[T]oggle Inlay [H]ints')
              end
            '';
        };

        lsp-format.enable = true;
        lsp-lines.enable = true;
        none-ls = {
          enable = true;
          sources = {
            code_actions = {
              gitsigns.enable = true;
              statix.enable = true;
            };

            diagnostics = {
              checkstyle.enable = true;
              deadnix.enable = true;
              statix.enable = true;
              pylint.enable = true;
            };

            formatting = {
              nixfmt.enable = true;
              stylua.enable = true;
              shfmt.enable = true;
              google_java_format.enable = false;
              markdownlint.enable = true;
              prettier = {
                enable = false;
                disableTsServerFormatter = true;
              };
            };
          };
        };

        typescript-tools.enable = true;
        rustaceanvim = {
          enable = true;
          settings = {
            server = {
              load_vscode_settings = true;
              default_settings.rust-analyzer = {
                cargo.features = "all";
                check = {
                  command = "clippy";
                  extraArgs = lib.mkDefault [ "--" ];
                  allTargets = true;
                };

                assist = {
                  emitMustUse = true;
                  expressionFillDefault = "default";
                };

                completion = {
                  termSearch.enable = true;
                  fullFunctionSignatures.enable = true;
                  privateEditable.enable = true;
                };

                diagnostics.styleLints.enable = true;
                imports = {
                  granularity.enforce = true;
                  preferPrelude = true;
                };

                inlayHints = {
                  closureReturnTypeHints.enable = "with_block";
                  closureStyle = "rust_analyzer";
                };

                lens.references = {
                  adt.enable = true;
                  enumVariant.enable = true;
                  method.enable = true;
                };

                interpret.tests = true;
                workspace.symbol.search.scope = "workspace_and_dependencies";
                typing.autoClosingAngleBrackets.enable = true;
              };

              dap.adapter = {
                command = "${pkgs.lldb}/bin/lldb-dap";
                type = "executable";
              };
            };
          };
        };

        nix.enable = true;
        crates.enable = true;
      };
    };
}
