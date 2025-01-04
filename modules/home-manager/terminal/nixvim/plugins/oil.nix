{
  enable = true;

  settings = {
    columns = ["icon"];
    view_options.show_hidden = true;
    keymaps = {
      "<C-r>" = "actions.refresh";
      "<leader>qq" = "actions.close";
      "<C-s>" = false; # Used for writing a buffer.
    };
  };
}
