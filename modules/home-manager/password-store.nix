{
  pkgs,
  hmOptions,
  ...
}: {
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: with exts; [pass-import pass-otp]);

    settings.PASSWORD_STORE_DIR = "/home/${hmOptions.username}/.password-store";
  };
}
