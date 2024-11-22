{
  enable = true;

  beacon.enable = true;
  ui.border = "rounded";
  hover.openCmd = "!firefox";
  codeAction = {
    showServerName = true;
    keys.quit = [
      "<Esc>"
      "q"
    ];
  };

  lightbulb.enable = false;
  rename.keys.quit = [
    "<C-k>"
    "<Esc>"
  ];

  outline.closeAfterJump = true;
}
