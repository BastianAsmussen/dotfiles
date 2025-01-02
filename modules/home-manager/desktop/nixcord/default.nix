{inputs, ...}: {
  imports = [
    inputs.nixcord.homeManagerModules.nixcord

    ./plugins
  ];

  programs.nixcord = {
    enable = true;

    config.themeLinks = [
      "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
    ];

    extraConfig.IS_MAXIMISED = true;
  };
}
