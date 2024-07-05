{
  config,
  pkgs,
  ...
}: {
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

  services.xserver = {
    enable = true;

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  users.users.bastian = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "libvirt"];

    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPc8Md/RuoiNaFIieZ2hTQ6z2R+bE8xealvVhs4omoq3AAAABHNzaDo= bastian@asmussen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUlnObPZOCziYmtmSH/+lPBwQwEx8mpFh0YLF2YmBsO"
    ];
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

  system.stateVersion = "24.05";
}
