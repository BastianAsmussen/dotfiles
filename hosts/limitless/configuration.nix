{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  sshServer.enable = true;

  nvidia.enable = true;
  sddm.enable = true;
  gnome.enable = true;

  pipewire.enable = true;
  hardware.pulseaudio.enable = false;

  monero = {
    enable = true;

    mining = {
      enable = true;
      wallet = "4977HG2wAcf4MJzM5Q5eK3CY1W6tEYmytQxR96gHhdMPWGZ95mwEiWiBo1vEyJxEynMYXBvCTTwzBGPtq24A9pDM1CXx55Y";
      maxUsagePercentage = 25;
    };
  };

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };

  networking = {
    hostName = "limitless";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Copenhagen";

  i18n.defaultLocale = "en_DK.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_DK.UTF-8";
    LC_IDENTIFICATION = "en_DK.UTF-8";
    LC_MEASUREMENT = "en_DK.UTF-8";
    LC_MONETARY = "en_DK.UTF-8";
    LC_NAME = "en_DK.UTF-8";
    LC_NUMERIC = "en_DK.UTF-8";
    LC_PAPER = "en_DK.UTF-8";
    LC_TELEPHONE = "en_DK.UTF-8";
    LC_TIME = "en_DK.UTF-8";
  };

  console.keyMap = "dk";

  environment.systemPackages = with pkgs; [
    eza
    ripgrep
    gitui
    bitwarden
    qbittorrent
    discord
    spotify
    mpv
    wget
    neofetch
    rustup
    go
    manix
    btop
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    openmoji-color
  ];
}
