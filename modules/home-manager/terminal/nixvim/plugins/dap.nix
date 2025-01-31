{pkgs, ...}: {
  programs.nixvim = {
    plugins = {
      dap = {
        enable = true;

        signs = {
          dapBreakpoint = {
            text = "";
            texthl = "DapBreakpoint";
          };

          dapBreakpointCondition = {
            text = "";
            texthl = "DapBreakpointCondition";
          };

          dapLogPoint = {
            text = "";
            texthl = "DapLogPoint";
          };
        };

        adapters.executables.lldb.command = "${pkgs.lldb}/bin/lldb-dap";
      };

      dap-ui = {
        enable = true;

        settings = {
          floating.mappings.close = ["<ESC>" "q"];
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

    extraConfigLua =
      # lua
      ''
        require('dap').listeners.after.event_initialized['dapui_config'] = require('dapui').open
        require('dap').listeners.before.event_terminated['dapui_config'] = require('dapui').close
        require('dap').listeners.before.event_exited['dapui_config'] = require('dapui').close
      '';
  };
}
