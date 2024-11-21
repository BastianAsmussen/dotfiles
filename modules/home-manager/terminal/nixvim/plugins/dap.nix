{
  programs.nixvim.plugins = {
    cmp-dap.enable = true;
    dap = {
      enable = true;

      extensions = {
        dap-ui = {
          enable = true;

          floating.mappings.close = ["<ESC>" "q"];
        };

        dap-virtual-text.enable = true;
      };

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
    };
  };
}
