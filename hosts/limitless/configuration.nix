{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  ssh.server.enable = true;

  nvidia.enable = true;
  goxlr.enable = true;

  desktop = {
    environment.gnome.enable = true;
    greeter.gdm.enable = true;
  };

  monero = {
    gui.enable = true;

    mining = {
      enable = false;

      pool = "pool.hashvault.pro:80";
      wallet = "8AzWTLBtPhkBqAU1m9TQW42LTtPwoKb4s4Sgo4uYY6TY1pNrrKYj2vFgGW9D5sBqi8VStmgViAZC82GfVcsqqLq77uJtWE7";
      maxUsagePercentage = 25;
    };
  };

  bootloader.isMultiboot = true;
}
