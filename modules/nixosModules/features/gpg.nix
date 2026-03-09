{
  flake.nixosModules.gpg = {pkgs, ...}: {
    programs.gnupg.agent = {
      enable = true;

      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
      settings = {
        default-cache-ttl = 60;
        max-cache-ttl = 120;
        ttyname = "$GPG_TTY";
      };
    };
  };
}
