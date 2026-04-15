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

    # Create root's .gnupg to avoid gpg-agent profile errors on login.
    systemd.tmpfiles.rules = ["d /root/.gnupg 0700 root root -"];
  };
}
