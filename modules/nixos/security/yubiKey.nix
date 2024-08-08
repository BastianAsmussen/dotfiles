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
    programs.ssh.startAgent = false; # Disallow the SSH agent.

    services = {
      udev.packages = [pkgs.yubikey-personalization];
      pcscd.enable = true;
    };

    security.pam = {
      services = {
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };

      u2f = {
        enable = true;

        interactive = true;
        cue = true;

        origin = "pam://yubikey";
        authFile = pkgs.writeText "u2f-mappings" (lib.concatStrings [
          config.home-manager.username
          ":<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>"
          ":<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>"
        ]);
      };
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
