{inputs, ...}: let
  hardware = inputs.nixos-hardware.nixosModules;
in {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix

    hardware.common-cpu-amd
  ];

  ssh.server.enable = true;
  nix.remoteBuilder.enable = true;

  nvidia.enable = true;
  goxlr.enable = true;

  gaming.enable = true;

  desktop = {
    environment.hyprland = {
      enable = true;

      monitors = [
        "DP-1, 1920x1080@240, 1920x0, 1"
        "HDMI-A-1, 1920x1080@60, 0x0, 1"
      ];
    };

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
