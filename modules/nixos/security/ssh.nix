{
  lib,
  config,
  pkgs,
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
          ClientAliveCountMax = 5;
          ClientAliveInterval = 60;
          PasswordAuthentication = false;
          AuthenticationMethods = "publickey";
          PubkeyAuthentication = "yes";
          PermitEmptyPasswords = false;
          ChallengeResponseAuthentication = false;
          X11Forwarding = false;
          PermitUserEnvironment = "no";
          AllowAgentForwarding = "no";
          AllowTcpForwarding = "no";
          PermitTunnel = "no";
          UsePAM = false;
          KbdInteractiveAuthentication = false;
          KexAlgorithms = [
            "curve25519-sha256"
            "curve25519-sha256@libssh.org"
            "diffie-hellman-group16-sha512"
            "diffie-hellman-group18-sha512"
            "diffie-hellman-group-exchange-sha256"
            "sntrup761x25519-sha512@openssh.com"
          ];

          Macs = [
            "hmac-sha2-512-etm@openssh.com"
            "hmac-sha2-256-etm@openssh.com"
            "umac-128-etm@openssh.com"
          ];
        };
      };

      fail2ban = {
        enable = true;

        extraPackages = with pkgs; [
          nftables
          ipset
        ];

        ignoreIP = [
          "127.0.0.0/8" # localhost
          "192.168.0.0/16" # Local Network
          "10.0.0.0/8" # WireGuard
        ];

        maxretry = 5;
        banaction = "nftables-multiport";
        banaction-allports = lib.mkDefault "nftables-allport";
        bantime = "10m";
        bantime-increment = {
          enable = true;

          rndtime = "30m";
          overalljails = true;
          multipliers = "4 8 16 32 64 128 256 512 1024 2048";
          maxtime = "1w";
        };

        daemonSettings.Definition = {
          loglevel = "INFO";
          logtarget = "/var/log/fail2ban/fail2ban.log";
          socket = "/run/fail2ban/fail2ban.sock";
          pidfile = "/run/fail2ban/fail2ban.pid";
          dbfile = "/var/lib/fail2ban/fail2ban.sqlite3";
          dbpurageage = "1d";
        };

        jails.sshd.settings = {
          enabled = true;

          filter = "sshd[mode=aggressive]";
          port = builtins.concatStringsSep "," (map toString config.services.openssh.ports);
        };
      };
    };
  };
}
