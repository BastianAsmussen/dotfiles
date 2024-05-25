{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
    ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable experimental features.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Networking.
  networking.hostName = "asmussen";
  networking.networkmanager.enable = true;

  # Timezone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
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

  # Enable Gnome.
  services.xserver = {
    enable = true;
    
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    videoDrivers = [ "nvidia" ];
  };
  
  # Enable nVidia drivers.
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
  
  # Configure keymap in X11.
  services.xserver = {
    layout = "dk";
  #  xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;

    pulse.enable = true;
  };

  # Create user.
  users.users.bastian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDo3d2gHl1Kw7OWtR8LhgY+bHOgdPbz2OuAvGF5oh2r bastian@asmussen.tech" ];
    
    packages = with pkgs; [
      brave
      neovim
      neofetch
      discord
      git
      goxlr-utility
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "bastian" = import ./home.nix;
    };
  };

  services.openssh.enable = true;

  system.stateVersion = "23.11";
}
