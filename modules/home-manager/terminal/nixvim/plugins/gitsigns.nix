{config, ...}: {
  programs.nixvim.plugins.gitsigns = {
    enable = true;

    settings = {
      current_line_blame = true;
      trouble = config.programs.nixvim.plugins.trouble.enable;
    };
  };
}
