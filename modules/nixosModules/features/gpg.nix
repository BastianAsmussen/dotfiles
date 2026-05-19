{
  flake.nixosModules.gpg =
    { pkgs, ... }:
    {
      programs = {
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          enableExtraSocket = true;
          pinentryPackage = pkgs.pinentry-gnome3;
          settings = {
            default-cache-ttl = 60;
            max-cache-ttl = 120;
          };
        };

        # Prevent the OpenSSH agent from starting; gpg-agent serves SSH keys.
        ssh.startAgent = false;
      };

      environment.shellInit =
        # sh
        ''
          export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

          if [ -z "$SSH_CONNECTION" ]; then
            export GPG_TTY=$(tty)

            gpgconf --launch gpg-agent >/dev/null 2>&1 || true
          fi
        '';

      # gpg-agent's profile.d script runs for all users including root.
      # Without a .gnupg dir, root's shell spews gpg-connect-agent errors on login.
      systemd.tmpfiles.rules = [ "d /root/.gnupg 0700 root root -" ];
    };
}
