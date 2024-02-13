local M = {}

M.general = {
  n = {
    ["<C-h>"] = {
      "<cmd> TmuxNavigateLeft <CR>",
      "Left Window"
    },
    ["<C-l>"] = {
      "<cmd> TmuxNavigateRight <CR>",
      "Right Window"
    },
    ["<C-j>"] = {
      "<cmd> TmuxNavigateUp <CR>",
      "Upper Window"
    },
    ["<C-k>"] = {
      "<cmd> TmuxNavigateDown <CR>",
      "Lower Window"
    },
  },
}

M.dap = {
   n = {
    ["<leader>db"] = {
      "<cmd> DapToggleBreakpoint <CR>",
      "Toggle Breakpoint",
    },
    ["<leader>dus"] = {
      function ()
        local widgets = require("dap.ui.widgets");
        local sidebar = widgets.sidebar(widgets.scopes);

        sidebar.open();
      end,
      "Open Debug View",
    }
  },
}

M.crates = {
  n = {
    ["<leader>rcu"] = {
      function ()
        require("crates").upgrade_all_crates()
      end,
      "Update Crates"
    },
  },
}

return M

