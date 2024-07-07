{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  nvidia.enable = true;
  ssh.enable = true;

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

  services.xserver = {
    enable = true;
    xkb.layout = "dk";

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    gitui
    eza
    ripgrep
    mullvad-vpn
    qbittorrent
    mpv
    discord
    spotify
    neofetch
    bitwarden
    wget
    deadnix
    btop
  ];

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  programs = {
    zsh.enable = true;
    virt-manager.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
    openmoji-color
  ];
}
