{
  flake.nixosModules.gpg =
    { config, pkgs, ... }:
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
          # Set SSH_AUTH_SOCK to non-conflicting path over SSH.
          if [ -n "$SSH_CONNECTION" ] && [ -S "$HOME/.ssh/gpg-agent-forward.ssh" ]; then
            export SSH_AUTH_SOCK="$HOME/.ssh/gpg-agent-forward.ssh"
          else
            export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
          fi

          # Route gpg to the forwarded signing socket over SSH.
          if [ -n "$SSH_CONNECTION" ] && [ -S "$HOME/.gnupg-fwd/S.gpg-agent" ]; then
            export GNUPGHOME="$HOME/.gnupg-fwd"
          fi

          if [ -z "$SSH_CONNECTION" ]; then
            export GPG_TTY=$(tty)

            gpgconf --launch gpg-agent >/dev/null 2>&1 || true
          fi
        '';

      # gpg-agent's profile.d script runs for all users including root.
      # Without a .gnupg dir, the shell spews gpg-connect-agent errors on login
      # and ssh gpg-agent socket forwarding (RemoteForward) fails to bind.
      systemd.tmpfiles.rules =
        let
          inherit (config.preferences.user) name;
        in
        [
          "d /root/.gnupg 0700 root root -"
          "d /home/${name}/.gnupg 0700 ${name} ${name} -"
          "d /home/${name}/.gnupg-fwd 0700 ${name} ${name} -"
          "f /home/${name}/.gnupg-fwd/gpg.conf 0600 ${name} ${name} - no-autostart"
          "L+ /home/${name}/.gnupg-fwd/pubring.kbx - - - - /home/${name}/.gnupg/pubring.kbx"
          "L+ /home/${name}/.gnupg-fwd/trustdb.gpg - - - - /home/${name}/.gnupg/trustdb.gpg"
        ];
    };
}
