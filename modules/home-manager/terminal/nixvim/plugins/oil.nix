{
  enable = true;

  settings = {
    columns = ["icon"];
    view_options.show_hidden = true;
    keymaps = {
      "<C-r>" = "actions.refresh";
      "<leader>qq" = "actions.close";
    };
  };
}
