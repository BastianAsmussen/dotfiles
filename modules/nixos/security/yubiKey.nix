{
  lib,
  config,
  pkgs,
  ...
}: {
  options.yubiKey.enable = lib.mkEnableOption "Enables YubiKey support.";

  config = lib.mkIf config.yubiKey.enable {
    gpg.enable = true; # Make sure GPG is enabled.
    programs.ssh.startAgent = false; # Disallow the SSH agent.

    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    environment = {
      systemPackages = with pkgs; [
        yubikey-personalization
      ];

      shellInit = ''
        gpg-connect-agent /bye
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      '';
    };
  };
}
