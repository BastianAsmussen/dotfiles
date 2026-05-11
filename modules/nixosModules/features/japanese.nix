{
  flake.nixosModules.japanese =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.japanese;
    in
    {
      options.japanese.enable = lib.mkEnableOption "Japanese locale and fcitx5 input method";

      config = lib.mkIf cfg.enable {
        i18n = {
          defaultLocale = lib.mkForce "ja_JP.UTF-8";
          extraLocales = [ "ja_JP.UTF-8/UTF-8" ];
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
      };
    };
}
