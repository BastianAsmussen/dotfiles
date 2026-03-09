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
          gpg-connect-agent /bye

          export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        '';
    };
  };
}
