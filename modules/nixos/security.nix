{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    gpg.enable = lib.mkEnableOption "Enables GPG services.";
    ssh.enable = lib.mkEnableOption "Enables SSH server.";
    vpn.enable = lib.mkEnableOption "Enables MullvadVPN.";
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
  ];
}
