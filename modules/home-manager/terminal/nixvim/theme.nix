{
  stylix.targets.nixvim.enable = false;

  programs.nixvim.colorschemes.catppuccin = {
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
}
