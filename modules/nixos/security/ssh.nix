{
  lib,
  config,
  ...
}: {
  options.ssh.server.enable = lib.mkEnableOption "Enable SSH server.";

  config = lib.mkIf config.ssh.server.enable {
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
