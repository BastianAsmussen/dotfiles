{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.yubiKey;
in {
  options.yubiKey.enable = lib.mkEnableOption "Enables YubiKey support.";

  config = lib.mkIf (cfg.enable && config.gpg.enable) {
    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    programs.ssh.startAgent = false; # Disallow the SSH agent.
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
