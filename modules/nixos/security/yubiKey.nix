{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.yubiKey;
in {
  options.yubiKey.enable = lib.mkEnableOption "Enables YubiKey support.";

  config = lib.mkIf cfg.enable {
    gpg.enable = true; # Make sure GPG is enabled.
    programs.ssh.startAgent = false; # Disallow the SSH agent.

    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    environment = {
      systemPackages = [pkgs.yubikey-personalization];

      shellInit = ''
        gpg-connect-agent /bye
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      '';
    };
  };
}
