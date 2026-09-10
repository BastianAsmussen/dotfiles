{
  # Colorscheme. Stylix drives everything else; nixvim opts out.
  flake.nixvimModules.theme =
    { ... }:
    {
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
