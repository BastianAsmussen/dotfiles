{
  # DAP, its UI, and the adapters wired up for it.
  flake.nixvimModules.debugging =
    { lib, pkgs, ... }:
    {
      plugins = {
        dap = {
          enable = true;
          signs = {
            dapBreakpoint = {
              text = "";
              texthl = "DapBreakpoint";
            };

            dapBreakpointCondition = {
              text = "";
              texthl = "DapBreakpointCondition";
            };

            dapLogPoint = {
              text = "";
              texthl = "DapLogPoint";
            };
          };

          adapters.executables.lldb.command = "${pkgs.lldb}/bin/lldb-dap";
        };

        dap-ui = {
          enable = true;
          settings = {
            floating.mappings.close = [
              "<ESC>"
              "q"
            ];
            icons = {
              expanded = "▾";
              collapsed = "▸";
              current_frame = "*";
            };

            controls = {
              icons = {
                pause = "⏸";
                play = "▶";
                step_into = "⏎";
                step_over = "⏭";
                step_out = "⏮";
                step_back = "b";
                run_last = "▶▶";
                terminate = "⏹";
                disconnect = "⏏";
              };
            };
          };
        };

        dap-virtual-text.enable = true;
        cmp-dap.enable = true;
      };
      extraConfigLua = lib.mkAfter ''
        local dap = require("dap")
        dap.listeners.after.event_initialized["dapui_config"] = require("dapui").open
        dap.listeners.before.event_terminated["dapui_config"] = require("dapui").close
        dap.listeners.before.event_exited["dapui_config"] = require("dapui").close
        local lldb_config = {
          {
            name = "Launch",
            type = "lldb",
            request = "launch",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = vim.fn.getcwd(),
            stopOnEntry = false,
          },
        }
        dap.configurations.c = lldb_config
        dap.configurations.cpp = lldb_config
      '';
    };
}
