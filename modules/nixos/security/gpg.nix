{
  lib,
  config,
  pkgs,
  ...
}: {
  options.gpg.enable = lib.mkEnableOption "Enable GPG agent.";

  config = lib.mkIf config.gpg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;

      pinentryPackage = pkgs.pinentry-curses;
      settings = {
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
        ttyname = "$GPG_TTY";
      };
    };
  };
}
