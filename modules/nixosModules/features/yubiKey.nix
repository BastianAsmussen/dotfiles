{
  flake.nixosModules.yubiKey = {pkgs, ...}: {
    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    programs.ssh.startAgent = false;
    environment = {
      systemPackages = with pkgs; [
        yubikey-personalization
        yubioath-flutter
      ];

      shellInit =
        # sh
        ''
          export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

          if [ -z "$SSH_CONNECTION" ]; then
            export GPG_TTY=$(tty)

            gpgconf --launch gpg-agent
            gpg-connect-agent updatestartuptty /bye > /dev/null
          fi
        '';
    };
  };
}
