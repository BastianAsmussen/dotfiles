{inputs, ...}: {
  imports = [
    inputs.nixcord.homeManagerModules.nixcord

    ./plugins
  ];

  programs.nixcord = {
    enable = true;

    discord.enable = false;
    vesktop.enable = true;

    config.themeLinks = [
      "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
    ];

    extraConfig.IS_MAXIMISED = true;
  };
}
