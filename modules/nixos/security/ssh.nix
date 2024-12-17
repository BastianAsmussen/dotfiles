{
  lib,
  config,
  ...
}: {
  options.ssh.server.enable = lib.mkEnableOption "Enable SSH server.";

  config = lib.mkIf config.ssh.server.enable {
    services = {
      openssh = {
        enable = true;

        allowSFTP = false;
        settings = {
          PermitRootLogin = "no";
          MaxAuthTries = 3;
          LoginGraceTime = 20;
          PasswordAuthentication = false;
          PermitEmptyPasswords = false;
          ChallengeResponseAuthentication = false;
          X11Forwarding = false;
          PermitUserEnvironment = "no";
          AllowAgentForwarding = "no";
          AllowTcpForwarding = "no";
          PermitTunnel = "no";
          UsePAM = false;
          KbdInteractiveAuthentication = false;
        };
      };

      fail2ban = {
        enable = true;

        maxretry = 3;
        bantime = "2w";
        bantime-increment = {
          enable = true;

          multipliers = "1 2 4 8 16 32 64";
          maxtime = "168h";
          overalljails = true;
        };

        jails.sshd.settings = {
          port = "ssh";
          logpath = "%(sshd_log)s";
          backend = "%(sshd_backend)s";
          maxretry = 3;
          findtime = "1d";
          bantime = "2w";
        };
      };
    };
  };
}
