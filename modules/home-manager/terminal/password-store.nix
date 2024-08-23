{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.wl-clipboard];

  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: with exts; [pass-import pass-otp]);

    settings.PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
  };
}
