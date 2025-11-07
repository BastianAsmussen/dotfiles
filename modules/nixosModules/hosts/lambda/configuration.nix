{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.lambda = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.host_lambda
    ];
  };

  flake.nixosModules.host_lambda = {pkgs, ...}: {
    imports = [
      self.nixosModules.base
      self.nixosModules.general
      self.nixosModules.desktop

      self.nixosModules.impermanence

      self.nixosModules.neovim
      self.nixosModules.gaming
      self.nixosModules.discord
      self.nixosModules.gimp
      self.nixosModules.hyprland
      self.nixosModules.telegram
      self.nixosModules.youtube-music

      # disko
      inputs.disko.nixosModules.disko
      self.diskoConfigurations.host_lambda
    ];

    programs.corectrl.enable = true;

    boot = {
      loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      supportedFilesystems.ntfs = true;

      kernelParams = ["quiet" "amd_pstate=guided" "processor.max_cstate=1"];
      kernelModules = ["coretemp" "cpuid" "v4l2loopback"];
    };

    boot.plymouth.enable = true;

    services.xserver.videoDrivers = ["amdgpu"];
    boot.initrd.kernelModules = ["amdgpu"];

    networking = {
      hostName = "lambda";
      networkmanager.enable = true;
      firewall.enable = false;
    };

    virtualisation.libvirtd.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    hardware.cpu.amd.updateMicrocode = true;

    services = {
      hardware.openrgb.enable = true;
      flatpak.enable = true;
      udisks2.enable = true;
      printing.enable = true;
    };

    programs = {
      adb.enable = true;
      niri.enable = true;
    };

    preferences.monitors = {
      primary = {
        primary = true;

        width = 1920;
        height = 1080;
        refreshRate = 240.0;
      };

      secondary = {
        width = 1920;
        height = 1080;

        x = -1920;
      };
    };

    environment.systemPackages = with pkgs; [
      wineWowPackages.stable
      wineWowPackages.waylandFull
      winetricks
      glib

      bs-manager
    ];

    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
    xdg.portal.enable = true;

    hardware.graphics.enable = true;

    system.stateVersion = "25.05";
  };
}
