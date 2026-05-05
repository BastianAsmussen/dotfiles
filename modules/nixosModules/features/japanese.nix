{
  flake.nixosModules.japanese = {
    lib,
    pkgs,
    ...
  }: {
    i18n = {
      defaultLocale = lib.mkForce "ja_JP.UTF-8";
      extraLocales = ["ja_JP.UTF-8/UTF-8"];
      extraLocaleSettings.LC_ALL = "ja_JP.UTF-8";
      inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            fcitx5-mozc
            fcitx5-gtk
          ];

          ignoreUserConfig = true;
          settings.globalOptions."Hotkey/TriggerKeys"."0" = "Control+Shift+space";
        };
      };
    };

    # environment.variables = {
    #   GTK_IM_MODULE = lib.mkForce "";
    #   QT_IM_MODULE = lib.mkForce "";
    # };
  };
}
