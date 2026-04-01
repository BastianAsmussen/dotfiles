{
  flake.nixosModules.gpg = {pkgs, ...}: {
    programs.gnupg.agent = {
      enable = true;

      enableSSHSupport = true;
      # Enable the extra socket so remote machines can use the local GPG agent
      # via SSH agent forwarding.
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-curses;
      settings = {
        default-cache-ttl = 60;
        max-cache-ttl = 120;
        ttyname = "$GPG_TTY";
      };
    };
  };
}
