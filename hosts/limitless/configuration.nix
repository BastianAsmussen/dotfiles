{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    
    inputs.home-manager.nixosModules.default
  ];
  
  nix.settings.experimental-features = ["nix-command" "flakes"];
  
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      efiSupport = true;
      device = "nodev";
    };
  };
  
  networking.hostName = "limitless";
  networking.networkmanager.enable = true;
  
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
    extraGroups = [ "wheel" "docker" "libvirt" ];
  };
  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "bastian" = import ./home.nix;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
  
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  programs.virt-manager.enable = true;
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  
  system.stateVersion = "24.05";

}

