{
  osConfig,
  pkgs,
  config,
  ...
}: let
  clipboardDependency =
    if osConfig.desktop.greeter.useWayland
    then pkgs.wl-clipboard
    else pkgs.xclip;
in {
  home.packages = [clipboardDependency];

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: with exts; [pass-import pass-otp]);

    settings.PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
  };
}
