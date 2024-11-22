{
  enable = true;

  sources = {
    completion.luasnip.enable = true;
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
      alejandra.enable = true;
      stylua.enable = true;
      shfmt.enable = true;
      google_java_format.enable = false;
      markdownlint.enable = true;
      prettier = {
        enable = true;

        disableTsServerFormatter = true;
      };
    };
  };
}
