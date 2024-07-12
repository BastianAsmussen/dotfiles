{
  lib,
  config,
  ...
}: {
  options.sshServer.enable = lib.mkEnableOption "Enable SSH server.";

  config = lib.mkIf config.sshServer.enable {
    services.openssh = {
      enable = true;

      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
