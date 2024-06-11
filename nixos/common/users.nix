{pkgs, ...}: {
  users = {
    mutableUsers = false;

    users = {
      root = {
        isSystemUser = true;

        hashedPassword = "$6$srlO2GV81MLXYysp$kkLK6KF5NBWQol2.sYsCi1ISaqSWGFJxR/CHbEssieZrl2MhosszX5f85PQPTxJ6gw.R3KcokaweBxDFiKpiJ1";
      };

      bastian = {
        isNormalUser = true;
        uid = 1000;

        group = "bastian";

        # shell = pkgs.zsh;
        # ignoreShellProgramCheck = true; # We can ignore the shell prompt check because we're using HM.

        extraGroups = [
          "wheel" # Enable 'sudo' for the user.
          "networkmanager" # Enable user to add and edit network connections.
          "docker"
          "libvirtd"
        ];

        hashedPassword = "$6$srlO2GV81MLXYysp$kkLK6KF5NBWQol2.sYsCi1ISaqSWGFJxR/CHbEssieZrl2MhosszX5f85PQPTxJ6gw.R3KcokaweBxDFiKpiJ1";
      };
    };

    groups.bastian.gid = 1000;
  };
}
