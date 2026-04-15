{
  flake.nixosModules.gpg = {pkgs, ...}: {
    programs.gnupg.agent = {
      enable = true;

      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      settings = {
        default-cache-ttl = 60;
        max-cache-ttl = 120;
      };
    };

    # gpg-agent's profile.d script runs for all users including root.
    # Without a .gnupg dir, root's shell spews gpg-connect-agent errors on login.
    systemd.tmpfiles.rules = ["d /root/.gnupg 0700 root root -"];
  };
}
