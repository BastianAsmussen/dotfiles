{
  # Colorscheme.
  flake.nixvimModules.theme = _: {
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        styles = {
          booleans = [
            "bold"
            "italic"
          ];

          conditionals = [
            "bold"
          ];
        };
      };
    };
  };
}
