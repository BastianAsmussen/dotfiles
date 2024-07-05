{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    gpg.enable = lib.mkEnableOption "Enable GPG services.";
    ssh.enable = lib.mkEnableOption "Enable SSH server.";
    vpn.enable = lib.mkEnableOption "Enable MullvadVPN.";
    yubiKey.enable = lib.mkEnableOption "Enable YubiKey support.";
  };

  config = lib.mkMerge [
    (lib.mkIf config.gpg.enable {
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    })

    (lib.mkIf config.ssh.enable {
      services.openssh = {
        enable = true;

        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    })

    (lib.mkIf config.vpn.enable {
      services = {
        mullvad-vpn.enable = true;
        resolved.enable = true;
      };
    })

    (lib.mkIf config.yubiKey.enable {
      gpg.enable = true; # Make sure GPG is enabled.

      programs.ssh.startAgent = false;

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
    })
  ];
}
