{inputs, ...}: {
  imports = [
    inputs.nixcord.homeModules.nixcord

    ./plugins.nix
  ];

  programs.nixcord = {
    enable = true;

    config.themeLinks = [
      "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
    ];

    extraConfig.IS_MAXIMISED = true;
  };

  stylix.targets.nixcord.enable = false;
}
