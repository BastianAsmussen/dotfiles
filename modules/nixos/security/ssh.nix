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

        settings = {
          UseDns = true;
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          MaxAuthTries = 3;
          LoginGraceTime = 20;
          ChallengeResponseAuthentication = "no";
          PermitUserEnvironment = "no";
          AllowAgentForwarding = "no";
          AllowTcpForwarding = "no";
          PermitTunnel = "no";
        };
      };

      fail2ban = let
        minsToSecs = mins: mins * 60;
      in {
        enable = true;

        maxretry = 5; # Ban IP after 5 failures.
        bantime = "24h"; # Ban IPs for one day on the first ban.
        bantime-increment = {
          enable = true; # Enable increment of bantime after each violation.
          multipliers = "1 2 4 8 16 32 64";
          maxtime = "168h"; # Do not ban for more than 1 week.
          overalljails = true; # Calculate the bantime based on all the violations.
        };

        jails.sshd.settings = {
          port = "ssh";
          logpath = "/var/log/auth.log";
          maxretry = 5;
          bantime = minsToSecs 30;
          ignoreip = "127.0.0.1/8";
        };
      };
    };
  };
}
