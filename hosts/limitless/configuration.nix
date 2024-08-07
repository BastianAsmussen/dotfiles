{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    (import ./disko-config.nix {inherit config;})
  ];

  ssh.server.enable = true;

  nvidia.enable = true;
  goxlr.enable = true;

  gdm.enable = true;
  gnome.enable = true;

  pipewire.enable = true;
  hardware.pulseaudio.enable = false;

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

  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    openmoji-color
  ];
}
